//
//  MMapTable.swift
//  Storage
//
//  Created by Valo on 2019/6/26.
//

import Foundation
import zlib

public class MMapKV {
    private var dictionary: [String: MMapable] = [:]
    private var mmapfile: MMapFile
    private var dataSize: Int = 0
    
    private var crc: Bool
    private var crcfile: MMapFile?
    private var crcdigest: uLong = 0

    private(set) var id: String

    public init(_ id: String = "com.enigma.mmapkv", crc: Bool = true) {
        // dir
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dir = (documentDirectory as NSString).appendingPathComponent("MMapKV")
        let fm = FileManager.default
        var isdir: ObjCBool = false
        let exist = fm.fileExists(atPath: dir, isDirectory: &isdir)
        if !exist || !isdir.boolValue {
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        // mmap file
        let path = (dir as NSString).appendingPathComponent(id)
        mmapfile = MMapFile(path: path)
        let bytes = [UInt8](Data(bytes: mmapfile.memory, count: mmapfile.size))
        let meta = MMapItem.enumerate(bytes)
        dictionary = meta.kv
        dataSize = meta.size
        self.id = id
        self.crc = crc

        // crc
        guard crc else { return }
        let crcName = (id as NSString).appendingPathExtension("crc") ?? (id + ".crc")
        let crcPath = (dir as NSString).appendingPathComponent(crcName)
        crcfile = MMapFile(path: crcPath)
        let buf = mmapfile.memory.assumingMemoryBound(to: Bytef.self)
        var calculated_crc: uLong = 0
        calculated_crc = crc32(calculated_crc, buf, uInt(dataSize))
        let stored_crc = crcfile!.memory.load(as: uLong.self)
        guard calculated_crc == stored_crc else {
            fatalError("check crc [\(id)] fail, claculated:\(calculated_crc), stored:\(stored_crc)\n")
        }
        self.crcdigest = calculated_crc
    }
    
    func updateCRC() {
        guard crc && crcfile != nil else { return }
        
        // calculate
        let buf = mmapfile.memory.assumingMemoryBound(to: Bytef.self)
        var crc: uLong = 0
        crc = crc32(crc, buf, uInt(dataSize))
        self.crcdigest = crc
        
        // store
        let size = MemoryLayout<uLong>.size
        let rbuf = UnsafeRawPointer(&crc)
        crcfile!.write(at: 0 ..< size, from: rbuf)
    }

    public subscript(key: String) -> MMapable? {
        get {
            return dictionary[key]
        }
        set(newValue) {
            dictionary[key] = newValue
            let mmaped = MMapItem(key: key, value: newValue)
            append(mmaped.storage)
        }
    }

    private func append(_ bytes: [UInt8]) {
        let len = bytes.count
        let end = dataSize + len
        if end > mmapfile.size {
            mmapfile.size = end
            resize()
        }
        let range: Range<Int> = Range(uncheckedBounds: (dataSize, end))
        mmapfile.write(at: range, from: bytes)
        dataSize = end
        updateCRC()
    }

    public func resize() {
        mmapfile.clear()
        dataSize = 0
        for (key, value) in dictionary {
            self[key] = value
        }
    }
}
