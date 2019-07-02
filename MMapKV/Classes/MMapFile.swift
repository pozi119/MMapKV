//
//  MMapFile.swift
//  MMapKV
//
//  Created by Valo on 2019/6/26.
//

import Foundation

public final class MMapFile {
    private var handle: Int32
    private var _size: Int = 0

    private(set) var path: String
    private(set) var memory: UnsafeMutableRawPointer

    let pagesize = Int(getpagesize())

    public init(path: String) {
        handle = open(path, O_RDWR | O_CREAT | O_APPEND, S_IRWXU)
        guard handle >= 0 else {
            let errmsg = String(cString: strerror(errno), encoding: .utf8) ?? ""
            fatalError("fail to open:\(path), \(errmsg)")
        }

        self.path = path

        var value = stat()
        stat(path, &value)
        defer {
            self.size = Int(value.st_size)
        }
        memory = mmap(nil, pagesize, PROT_READ | PROT_WRITE, MAP_SHARED, handle, 0)
    }

    deinit {
        munmap(self.memory, self._size)
        close(self.handle)
    }

    public var size: Int {
        get {
            return _size
        }
        set(value) {
            var actualSize = (((value - 1) / pagesize) + 1) * pagesize
            actualSize = actualSize > 0 ? actualSize : pagesize

            if actualSize != _size {
                munmap(memory, _size)
                _size = actualSize

                guard ftruncate(handle, off_t(actualSize)) == 0 else {
                    let errmsg = String(cString: strerror(errno), encoding: .utf8) ?? ""
                    fatalError("fail to truncate \(path)  to size \(actualSize), \(errmsg)")
                }

                memory = mmap(nil, actualSize, PROT_READ | PROT_WRITE, MAP_SHARED, handle, 0)
                guard memory != MAP_FAILED else {
                    let errmsg = String(cString: strerror(errno), encoding: .utf8) ?? ""
                    fatalError("fail to map \(path), \(errmsg)")
                }
            }
        }
    }

    public func sync() {
        msync(memory, _size, MS_SYNC)
    }

    public func async() {
        msync(memory, _size, MS_ASYNC)
    }

    public func remap() {
        munmap(memory, _size)
        memory = mmap(nil, _size, PROT_READ | PROT_WRITE, MAP_SHARED, handle, 0)
        guard memory != MAP_FAILED else {
            let errmsg = String(cString: strerror(errno), encoding: .utf8) ?? ""
            fatalError("fail to map \(path), \(errmsg)")
        }
    }

    public func write(at range: Range<Int>, from data: UnsafeRawPointer) {
        memcpy(memory.advanced(by: range.lowerBound), data, range.count)
    }

    public func read(at range: Range<Int>, to data: UnsafeMutableRawPointer) {
        memcpy(data, memory.advanced(by: range.lowerBound), range.count)
    }

    public func clear() {
        memset(memory, 0, _size)
    }
}
