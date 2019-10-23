//
//  AnyCodableTests.swift
//  MMapKV_Tests
//
//  Created by Valo on 2019/10/23.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AnyCodable
import MMapKV
import XCTest

class AnyCodableTests: XCTestCase {
    lazy var mmkv = MMKV<String, AnyCodable>("com.valo.mmkv.anycodable")
    let dictionary: [String: AnyCodable] = [
        "boolean": true,
        "integer": 1,
        "double": 3.14159265358979323846,
        "string": "string",
        "array": [1, 2, 3],
        "nested": [
            "a": "alpha",
            "b": "bravo",
            "c": "charlie",
        ],
    ]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testWrite() {
        for (key, val) in dictionary {
            mmkv[key] = val
        }
    }

    func testRead() {
        print("\n\(dictionary)\n")
        print("\n\(mmkv.dictionary)\n")
    }
}
