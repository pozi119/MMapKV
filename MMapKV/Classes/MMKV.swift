//
//  MMKV.swift
//  MMapKV
//
//  Created by Valo on 2019/6/26.
//

import AnyCoder
import Foundation
import zlib

private var pool: [String: MMKV] = [:]

public extension MMKV {
    class func create(_ id: String = "com.valo.mmkv",
                      basedir: String = "",
                      crc: Bool = true) -> MMKV {
        let dir = MMKV.directory(with: basedir)
        let path = (dir as NSString).appendingPathComponent(id)
        if let mmkv = pool[path] {
            return mmkv
        }
        let mmkv = MMKV(id, basedir: basedir, crc: crc)
        pool[path] = mmkv
        return mmkv
    }
}

public class MMKV {
    public private(set) var dictionary: [String: Primitive] = [:]

    private var file: File
    private var dataSize: Int = 0

    private var crc: Bool
    private var crcfile: File?
    private var crcdigest: uLong = 0

    private(set) var id: String

    public init(_ id: String = "com.valo.mmkv",
                basedir: String = "",
                crc: Bool = true) {
        // dir
        let dir = MMKV.directory(with: basedir)
        // mmap file
        let path = (dir as NSString).appendingPathComponent(id)
        file = File(path: path)
        let bytes = [UInt8](Data(bytes: file.memory, count: file.size))
        (dictionary, dataSize) = MMKV.decode(bytes)
        self.id = id
        self.crc = crc

        // crc
        guard crc else { return }
        let crcName = (id as NSString).appendingPathExtension("crc") ?? (id + ".crc")
        let crcPath = (dir as NSString).appendingPathComponent(crcName)
        crcfile = File(path: crcPath)
        let buf = file.memory.assumingMemoryBound(to: Bytef.self)
        var calculated_crc: uLong = 0
        calculated_crc = crc32(calculated_crc, buf, uInt(dataSize))
        let stored_crc = crcfile!.memory.load(as: uLong.self)
        if calculated_crc != stored_crc {
            updateCRC()
            assert(false, "check crc [\(id)] fail, claculated:\(calculated_crc), stored:\(stored_crc)\n")
        }
        crcdigest = calculated_crc
    }

    private class func directory(with basedir: String = "") -> String {
        var _basedir = basedir
        if _basedir.count == 0 {
            _basedir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        }
        let dir = (_basedir as NSString).appendingPathComponent("mmapkv")
        let fm = FileManager.default
        var isdir: ObjCBool = false
        let exist = fm.fileExists(atPath: dir, isDirectory: &isdir)
        if !exist || !isdir.boolValue {
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }

    private func updateCRC() {
        guard crc && crcfile != nil else { return }

        // calculate
        let buf = file.memory.assumingMemoryBound(to: Bytef.self)
        var crc: uLong = 0
        crc = crc32(crc, buf, uInt(dataSize))
        crcdigest = crc

        // store
        let size = MemoryLayout<uLong>.size
        let pointer = withUnsafePointer(to: &crc) { $0 }
        let rbuf = UnsafeRawPointer(pointer)
        crcfile!.write(at: 0 ..< size, from: rbuf)
    }

    private func append(_ bytes: [UInt8]) {
        let len = bytes.count
        let end = dataSize + len
        if end > file.size {
            file.size = end
            resize()
        }
        let range: Range<Int> = Range(uncheckedBounds: (dataSize, end))
        file.write(at: range, from: bytes)
        dataSize = end
        updateCRC()
    }

    public func resize() {
        file.clear()
        dataSize = 0
        for (key, val) in dictionary {
            self[key] = val
        }
    }
}

private let KeyFlag: [UInt8] = [0x4B, 0x45, 0x59]
private let ValFlag: [UInt8] = [0x56, 0x41, 0x4C]

private let OrderedTypes: [Any.Type] = [
    Any.self,
    Bool.self,
    Int.self, Int8.self, Int16.self, Int32.self, Int64.self,
    UInt.self, UInt8.self, UInt16.self, UInt32.self, UInt64.self,
    Float.self, Double.self,
    String.self, Data.self,
]

private func valueType(of flag: Int) -> Any.Type {
    return OrderedTypes[flag]
}

private func typeBytes(of value: Any?) -> [UInt8] {
    guard let value = value else { return [0] }
    let type = type(of: value)
    guard let idx = OrderedTypes.firstIndex(where: { type == $0 }) else { return [0] }
    return [UInt8(idx)]
}

private func toData(_ any: Any?) -> Data? {
    guard let obj = any else { return nil }
    var data: Data?
    switch obj {
    case let b as Bool: data = Data(integer: b ? 1 : 0)
    case let i as any BinaryInteger: data = Data(integer: i)
    case let f as any BinaryFloatingPoint: data = Data(floating: f)
    case let s as String: data = Data(s.bytes)
    case let d as Data: data = d
    default: break
    }
    if let data { return data }
    if JSONSerialization.isValidJSONObject(obj) {
        data = try? JSONSerialization.data(withJSONObject: obj, options: [])
    }
    if data == nil {
        var dic: Any?
        if let obj = obj as? any Codable {
            dic = try? ManyEncoder().encode(obj)
        } else {
            dic = try? AnyEncoder.encode(obj)
        }
        if let dic {
            data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        }
    }
    return data
}

extension MMKV {
    static func encode(_ element: (key: String, value: Primitive?)) -> [UInt8] {
        guard let keyData = toData(element.key) else {
            return []
        }
        let keyBytes = [UInt8](keyData)
        var valBytes = [UInt8]()
        if let valData = toData(element.value) {
            valBytes = [UInt8](valData)
        }

        func sizeBytes(of bytes: [UInt8]) -> [UInt8] {
            let size = bytes.count
            var sizeBytes = [UInt8]()
            for i in 0 ..< 4 {
                sizeBytes.append(UInt8(size >> (i * 8)))
            }
            return sizeBytes
        }

        let keySizeBytes = sizeBytes(of: keyBytes)
        let valSizeBytes = sizeBytes(of: valBytes)
        let valTypeBytes = typeBytes(of: element.value)

        var bytes = KeyFlag + keySizeBytes + keyBytes
        bytes += ValFlag + valSizeBytes + valTypeBytes + valBytes
        return bytes
    }

    static func decode(_ bytes: [UInt8]) -> ([String: Primitive], Int) {
        var offset: Int = 0
        var results: [String: Primitive] = [:]
        let total = bytes.count

        enum FLAG { case key, val }
        func parse(_ flag: FLAG) -> (Primitive?, Int) {
            let flagBuf = flag == .key  ? KeyFlag : ValFlag
            // flag bytes
            var start = offset
            var end = start + 3
            guard end <= total else { return (nil, offset) }
            var buf = [UInt8](bytes[start ..< end])
            if buf != flagBuf { return (nil, offset) }

            // size bytes
            start = end
            end = start + 4
            guard end <= total else { return (nil, offset) }
            buf = [UInt8](bytes[start ..< end])
            var size = 0
            for i in 0 ..< 4 {
                size |= Int(buf[i]) << (i * 8)
            }

            var type: Any.Type = String.self
            if flag == .val {
                // type byte
                start = end
                end = start + 1
                guard end <= total else { return (nil, offset) }
                let typeByte = bytes[start]
                type = valueType(of: Int(typeByte))
            }

            // value bytes
            start = end
            end = start + size
            guard end <= total else { return (nil, offset) }
            buf = [UInt8](bytes[start ..< end])
            let data = Data(buf)

            // to value
            var any: Any?
            switch type {
            case is Bool.Type: any = Int(data: data) > 0 ? true : false
            case let u as any BinaryInteger.Type: any = u.init(data: data) as any BinaryInteger
            case let u as any BinaryFloatingPoint.Type: any = u.init(data: data) as any BinaryFloatingPoint
            case is String.Type: any = String(bytes: buf)
            case is Data.Type: any = data
            default: break
            }
            guard let primitive = any as? Primitive else { return (nil, end) }
            return (primitive, end)
        }

        while offset < total {
            let (key, key_end) = parse(.key)
            if key == nil { break }

            offset = key_end
            let (val, val_end) = parse(.val)
            if offset == val_end { break }

            if let key = key as? String {
                results[key] = val
            }
            offset = val_end
        }

        return (results, offset)
    }
}

extension MMKV {
    public subscript(key: String) -> Primitive? {
        get {
            return dictionary[key]
        }
        set(newValue) {
            dictionary[key] = newValue
            let mmaped = MMKV.encode((key, newValue))
            append(mmaped)
        }
    }
}
