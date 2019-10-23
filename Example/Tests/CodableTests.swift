//
//  CodableTests.swift
//  MMapKV_Tests
//
//  Created by Valo on 2019/10/23.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import MMapKV
import XCTest

class CodableTests: XCTestCase {
    lazy var mmkv = MMKV<String, Person>("com.valo.mmkv.codable")
    let person = Person(name: "张三", age: 18, cotent: "我是张三".data(using: .utf8)!)

    override func setUp() {
    }

    override func tearDown() {
    }

    func testWrite() {
        mmkv["1"] = person
    }

    func testRead() {
        let p = mmkv["1"]
        assert(p != nil && p! == person)
    }
}
