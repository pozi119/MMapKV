//
//  MMapItem.swift
//  MMapKV
//
//  Created by Valo on 2019/6/26.
//

import Foundation

public protocol MMapable {}

extension Bool: MMapable {}
extension Int: MMapable {}
extension Int8: MMapable {}
extension Int16: MMapable {}
extension Int32: MMapable {}
extension Int64: MMapable {}
extension UInt: MMapable {}
extension UInt8: MMapable {}
extension UInt16: MMapable {}
extension UInt32: MMapable {}
extension UInt64: MMapable {}
extension Float: MMapable {}
extension Double: MMapable {}
extension Float80: MMapable {}
extension String: MMapable {}
extension Data: MMapable {}
extension Date: MMapable {}

fileprivate enum MMapType: UInt8 {
    fileprivate typealias RawValue = UInt8

    case bool = 1
    case int, int8, int16, int32, int64
    case uint, uint8, uint16, uint32, uint64
    case float, double, float80
    case string
    case data
    case date

    fileprivate init(value: MMapable) {
        switch value {
        case is Bool: self = .bool
        case is Int: self = .int
        case is Int8: self = .int8
        case is Int16: self = .int16
        case is Int32: self = .int32
        case is Int64: self = .int64
        case is UInt: self = .uint
        case is UInt8: self = .uint8
        case is UInt16: self = .uint16
        case is UInt32: self = .uint32
        case is UInt64: self = .uint64
        case is Float: self = .float
        case is Double: self = .double
        case is Float80: self = .float80
        case is String: self = .string
        case is Data: self = .data
        case is Date: self = .date
        default: fatalError("invalid type")
        }
    }
}

fileprivate let _MMapTypeMemorySizes: [MMapType: Int] =
    [
        .bool: MemoryLayout<Bool>.size,
        .int: MemoryLayout<Int>.size,
        .int8: MemoryLayout<Int8>.size,
        .int16: MemoryLayout<Int16>.size,
        .int32: MemoryLayout<Int32>.size,
        .int64: MemoryLayout<Int64>.size,
        .uint: MemoryLayout<UInt>.size,
        .uint8: MemoryLayout<UInt8>.size,
        .uint16: MemoryLayout<UInt16>.size,
        .uint32: MemoryLayout<UInt32>.size,
        .uint64: MemoryLayout<UInt64>.size,
        .float: MemoryLayout<Float>.size,
        .double: MemoryLayout<Double>.size,
        .float80: MemoryLayout<Float80>.size,
        .date: MemoryLayout<Double>.size,
    ]

fileprivate extension MMapType {
    var memsize: Int? {
        return _MMapTypeMemorySizes[self]
    }
}

/// MMaped
public struct MMapItem {
    private(set) var key: String
    private(set) var value: MMapable?
    private(set) var storage: [UInt8]

    private static let keyFlag: [UInt8] = [0x4B, 0x45, 0x59]
    private static let valueFlag: [UInt8] = [0x56, 0x41, 0x4C]

    private static func mmap_encode(_ value: MMapable?, isKey: Bool = true) -> (index: [UInt8], bytes: [UInt8]) {
        let flag: [UInt8] = isKey ? MMapItem.keyFlag : MMapItem.valueFlag
        var mmaptype: MMapType = .int
        var bytes: [UInt8]

        if value == nil {
            bytes = []
        } else {
            let val = value!
            switch val {
            case let val as String:
                mmaptype = .string
                bytes = [UInt8](val.data(using: .utf8)!)

            case let val as Data:
                mmaptype = .data
                bytes = [UInt8](val)

            default:
                mmaptype = .init(value: val)
                let memsize = mmaptype.memsize
                guard memsize != nil else { fatalError("invalid value type") }
                var _val = mmaptype == .date ? (val as! Date).timeIntervalSince1970 : val
                let buffer = UnsafeRawPointer(&_val)
                bytes = [UInt8](Data(bytes: buffer, count: memsize!))
            }
        }

        let size = bytes.count
        var index: [UInt8] = flag
        index.append(mmaptype.rawValue)
        for i in 0 ..< 4 {
            index.append(UInt8(size >> (i * 8)))
        }
        return (index, bytes)
    }

    private static func mmap_decode(_ bytes: [UInt8], to mmapType: MMapType) -> MMapable {
        switch mmapType {
        case .bool: return UnsafeRawPointer(bytes).load(as: Bool.self)
        case .int: return UnsafeRawPointer(bytes).load(as: Int.self)
        case .int8: return UnsafeRawPointer(bytes).load(as: Int8.self)
        case .int16: return UnsafeRawPointer(bytes).load(as: Int16.self)
        case .int32: return UnsafeRawPointer(bytes).load(as: Int32.self)
        case .int64: return UnsafeRawPointer(bytes).load(as: Int64.self)
        case .uint: return UnsafeRawPointer(bytes).load(as: UInt.self)
        case .uint8: return UnsafeRawPointer(bytes).load(as: UInt8.self)
        case .uint16: return UnsafeRawPointer(bytes).load(as: UInt16.self)
        case .uint32: return UnsafeRawPointer(bytes).load(as: UInt32.self)
        case .uint64: return UnsafeRawPointer(bytes).load(as: UInt64.self)
        case .float: return UnsafeRawPointer(bytes).load(as: Float.self)
        case .double: return UnsafeRawPointer(bytes).load(as: Double.self)
        case .float80: return UnsafeRawPointer(bytes).load(as: Float80.self)
        case .string: return String(bytes: bytes, encoding: .utf8) ?? ""
        case .data: return Data(bytes)
        case .date: return Date(timeIntervalSince1970: UnsafeRawPointer(bytes).load(as: Double.self))
        }
    }

    public init(key: String, value: MMapable?) {
        guard key.count > 0 else {
            fatalError("invalid key")
        }

        self.key = key
        self.value = value

        let keyTuple = MMapItem.mmap_encode(key)
        let valTuple = MMapItem.mmap_encode(value, isKey: false)

        storage = keyTuple.index + valTuple.index + keyTuple.bytes + valTuple.bytes
    }

    public static func enumerate(_ buffer: [UInt8]) -> (kv: [String: MMapable?], size: Int) {
        var offset: Int = 0
        var results: [String: MMapable?] = [:]

        let size = buffer.count
        while offset < size {
            let key_idx_start = offset
            let key_flag_end = key_idx_start + 3
            let key_type_idx = key_flag_end
            let key_len_start = key_idx_start + 4
            let key_len_end = key_idx_start + 8

            let val_idx_start = key_len_end
            let val_flag_end = val_idx_start + 3
            let val_type_idx = val_flag_end
            let val_len_start = val_idx_start + 4
            let val_len_end = val_idx_start + 8

            if val_len_end > size { break }

            let key_flag = [UInt8](buffer[key_idx_start ..< key_flag_end])
            let val_flag = [UInt8](buffer[val_idx_start ..< val_flag_end])
            if key_flag != MMapItem.keyFlag || val_flag != MMapItem.valueFlag { break }

            let key_type = MMapType(rawValue: buffer[key_type_idx])
            let val_type = MMapType(rawValue: buffer[val_type_idx])

            if key_type != MMapType.string || val_type == nil { break }

            let key_len_buf = [UInt8](buffer[key_len_start ..< key_len_end])
            let val_len_buf = [UInt8](buffer[val_len_start ..< val_len_end])

            var key_len = 0
            var val_len = 0
            for i in 0 ..< 4 {
                key_len |= Int(key_len_buf[i]) << (i * 8)
                val_len |= Int(val_len_buf[i]) << (i * 8)
            }

            if key_len == 0 { break }

            let key_start = val_len_end
            let key_end = key_start + key_len

            let key_buf = [UInt8](buffer[key_start ..< key_end])
            let key = MMapItem.mmap_decode(key_buf, to: .string) as! String

            if val_len == 0 {
                results[key] = nil
                offset = key_end
                continue
            }

            let val_start = key_end
            let val_end = val_start + val_len
            if val_end > size { break }

            let val_buf = [UInt8](buffer[val_start ..< val_end])
            let val = MMapItem.mmap_decode(val_buf, to: val_type!)
            results[key] = val

            offset = val_end
        }

        return (results, offset)
    }
}
