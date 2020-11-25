//
//  MMKV.swift
//  MMapKV
//
//  Created by Valo on 2019/6/26.
//

import AnyCoder
import Foundation
import zlib

private var pool: [String: Any] = [:]

public extension MMKV {
    class func create(_ id: String = "com.valo.mmkv",
                      basedir: String = "",
                      crc: Bool = true) -> MMKV {
        let dir = MMKV.directory(with: basedir)
        let path = (dir as NSString).appendingPathComponent(id)
        if let mmkv = pool[path] as? MMKV {
            return mmkv
        }
        let mmkv = MMKV(id, basedir: basedir, crc: crc)
        pool[path] = mmkv
        return mmkv
    }
}

public class MMKV<Key, Value> where Key: Hashable {
    public private(set) var dictionary: [Key: Value] = [:]

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
        guard calculated_crc == stored_crc else {
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
        for (key, value) in dictionary {
            self[key] = value
        }
    }
}

private let keyFlag: [UInt8] = [0x4B, 0x45, 0x59]
private let valueFlag: [UInt8] = [0x56, 0x41, 0x4C]

private func toData(_ any: Any?) -> Data? {
    guard let obj = any else { return nil }
    if let primitive = obj as? Primitive {
        if let data = Data(primitive: primitive) {
            return data
        }
    }
    var data: Data?
    if JSONSerialization.isValidJSONObject(obj) {
        data = try? JSONSerialization.data(withJSONObject: obj, options: [])
    }
    if data == nil {
        if let dic = try? AnyEncoder.encode(obj) {
            data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        }
    }
    return data
}

extension MMKV {
    static func encode(_ element: (Key, Value?)) -> [UInt8] {
        guard let keyData = toData(element.0) else {
            return []
        }
        let keyBytes = [UInt8](keyData)
        var valueBytes = [UInt8]()
        if let valueData = toData(element.1) {
            valueBytes = [UInt8](valueData)
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
        let valueSizeBytes = sizeBytes(of: valueBytes)

        var bytes = keyFlag + keySizeBytes + keyBytes
        bytes += valueFlag + valueSizeBytes + valueBytes
        return bytes
    }

    static func decode(_ bytes: [UInt8]) -> ([Key: Value], Int) {
        var offset: Int = 0
        var results: [Key: Value] = [:]
        let total = bytes.count

        func parse<T>(type: T.Type, flag: [UInt8]) -> (T?, Int) {
            var start = offset
            var end = start + 3
            guard end <= total else { return (nil, offset) }
            var buf = [UInt8](bytes[start ..< end])
            if buf != flag { return (nil, offset) }

            start = end
            end = start + 4
            guard end <= total else { return (nil, offset) }
            buf = [UInt8](bytes[start ..< end])
            var size = 0
            for i in 0 ..< 4 {
                size |= Int(buf[i]) << (i * 8)
            }

            start = end
            end = start + size
            guard end <= total else { return (nil, offset) }
            buf = [UInt8](bytes[start ..< end])
            let data = Data(buf)

            var any: Any?
            switch type {
                case is Int.Type: any = Int(primitive: data)
                case is Int8.Type: any = Int8(primitive: data)
                case is Int16.Type: any = Int16(primitive: data)
                case is Int32.Type: any = Int32(primitive: data)
                case is Int64.Type: any = Int64(primitive: data)
                case is UInt.Type: any = UInt(primitive: data)
                case is UInt8.Type: any = UInt8(primitive: data)
                case is UInt16.Type: any = UInt16(primitive: data)
                case is UInt32.Type: any = UInt32(primitive: data)
                case is UInt64.Type: any = UInt64(primitive: data)
                case is Bool.Type: any = Bool(primitive: data)
                case is Float.Type: any = Float(primitive: data)
                case is Double.Type: any = Double(primitive: data)
                case is String.Type: any = String(primitive: data)
                case is Data.Type: any = Data(primitive: data)
                default: break
            }
            if any == nil {
                any = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            if let r = any as? T {
                return (r, end)
            }
            if let dic = any as? [String: Any] {
                var _dic: [String: Primitive] = [:]
                dic.forEach { _dic[$0.key] = ($0.value as? Primitive) ?? "" }
                if let r = try? AnyDecoder.decode(T.self, from: _dic) {
                    return (r, end)
                }
            }
            return (nil, end)
        }

        while offset < total {
            let (key, key_end) = parse(type: Key.self, flag: keyFlag)
            if key == nil { break }

            offset = key_end
            let (val, val_end) = parse(type: Value.self, flag: valueFlag)
            if offset == val_end { break }

            results[key!] = val
            offset = val_end
        }

        return (results, offset)
    }
}

extension MMKV {
    public subscript(key: Key) -> Value? {
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
