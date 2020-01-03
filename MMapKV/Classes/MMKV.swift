//
//  MMKV.swift
//  MMKV
//
//  Created by Valo on 2019/6/26.
//

import Foundation
import zlib

private var pool: [String: Any] = [:]

public extension MMKV {
    class func fromPool(_ id: String = "com.valo.mmkv",
                        directory: String = "",
                        crc: Bool = true) -> MMKV {
        let dir = MMKV.kvfileDirectory(with: directory)
        let path = (dir as NSString).appendingPathComponent(id)
        if let mmkv = pool[path] as? MMKV {
            return mmkv
        }
        let mmkv = MMKV(id, directory: directory, crc: crc)
        pool[path] = mmkv
        return mmkv
    }
}

public class MMKV<Key, Value> where Key: Hashable, Key: Codable, Value: Codable {
    public private(set) var dictionary: [Key: Value] = [:]

    private var kvfile: KVFile
    private var dataSize: Int = 0

    private var crc: Bool
    private var crcfile: KVFile?
    private var crcdigest: uLong = 0

    private(set) var id: String

    public init(_ id: String = "com.valo.mmkv",
                directory: String = "",
                crc: Bool = true) {
        // dir
        let dir = MMKV.kvfileDirectory(with: directory)
        // mmap file
        let path = (dir as NSString).appendingPathComponent(id)
        kvfile = KVFile(path: path)
        let bytes = [UInt8](Data(bytes: kvfile.memory, count: kvfile.size))
        (dictionary, dataSize) = MMKV.decode(bytes)
        self.id = id
        self.crc = crc

        // crc
        guard crc else { return }
        let crcName = (id as NSString).appendingPathExtension("crc") ?? (id + ".crc")
        let crcPath = (dir as NSString).appendingPathComponent(crcName)
        crcfile = KVFile(path: crcPath)
        let buf = kvfile.memory.assumingMemoryBound(to: Bytef.self)
        var calculated_crc: uLong = 0
        calculated_crc = crc32(calculated_crc, buf, uInt(dataSize))
        let stored_crc = crcfile!.memory.load(as: uLong.self)
        guard calculated_crc == stored_crc else {
            updateCRC()
            assert(false, "check crc [\(id)] fail, claculated:\(calculated_crc), stored:\(stored_crc)\n")
        }
        crcdigest = calculated_crc
    }

    private class func kvfileDirectory(with directory: String) -> String {
        var dir = directory
        if dir.count == 0 {
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            dir = (documentDirectory as NSString).appendingPathComponent("vmmkv")
        }
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
        let buf = kvfile.memory.assumingMemoryBound(to: Bytef.self)
        var crc: uLong = 0
        crc = crc32(crc, buf, uInt(dataSize))
        crcdigest = crc

        // store
        let size = MemoryLayout<uLong>.size
        let rbuf = UnsafeRawPointer(&crc)
        crcfile!.write(at: 0 ..< size, from: rbuf)
    }

    private func append(_ bytes: [UInt8]) {
        let len = bytes.count
        let end = dataSize + len
        if end > kvfile.size {
            kvfile.size = end
            resize()
        }
        let range: Range<Int> = Range(uncheckedBounds: (dataSize, end))
        kvfile.write(at: range, from: bytes)
        dataSize = end
        updateCRC()
    }

    public func resize() {
        kvfile.clear()
        dataSize = 0
        for (key, value) in dictionary {
            self[key] = value
        }
    }
}

private let MMapKeyFlag: [UInt8] = [0x4B, 0x45, 0x59]
private let MMapValueFlag: [UInt8] = [0x56, 0x41, 0x4C]
private let MMapEncoder = JSONEncoder()
private let MMapDecoder = JSONDecoder()

extension MMKV {
    static func encode(_ element: (Key, Value?)) -> [UInt8] {
        guard let keyData = try? MMapEncoder.encode(element.0) else {
            return []
        }
        let keyBytes = [UInt8](keyData)
        var valueBytes = [UInt8]()
        if let valueData = try? MMapEncoder.encode(element.1) {
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

        var bytes = MMapKeyFlag + keySizeBytes + keyBytes
        bytes += MMapValueFlag + valueSizeBytes + valueBytes
        return bytes
    }

    static func decode(_ bytes: [UInt8]) -> ([Key: Value], Int) {
        var offset: Int = 0
        var results: [Key: Value] = [:]
        let total = bytes.count

        func parse<T: Codable>(type: T.Type, flag: [UInt8]) -> (T?, Int) {
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
            let r = try? MMapDecoder.decode(T.self, from: Data(buf))
            return (r, end)
        }

        while offset < total {
            let (key, key_end) = parse(type: Key.self, flag: MMapKeyFlag)
            if key == nil { break }

            offset = key_end
            let (val, val_end) = parse(type: Value.self, flag: MMapValueFlag)
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
