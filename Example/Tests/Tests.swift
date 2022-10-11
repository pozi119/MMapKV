import MMapKV
import XCTest

class Tests: XCTestCase {
    lazy var mmkv = MMKV("com.valo.mmkv.default")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBytes() {
        let a: UInt64 = 0xffffffffffffffff
        print(a.bytes)
        let bytes:[UInt8] = [255, 255, 255, 255, 255, 255, 255, 255]
        let b = UInt64(data: Data(bytes))
        print(b)
    }

    func testWrite() {
        // This is an example of a functional test case.
        mmkv["b"] = 0
        mmkv["i"] = -1
        mmkv["i8"] = -8
        mmkv["i16"] = -16
        mmkv["i32"] = -32
        mmkv["i64"] = -64
        mmkv["u"] = 1
        mmkv["u8"] = 8
        mmkv["u16"] = 16
        mmkv["u32"] = 32
        mmkv["u64"] = 64
        mmkv["f"] = 11
        mmkv["d"] = 22
        mmkv["f80"] = 80
        mmkv["str"] = "1000"
        mmkv["max"] = Int.min
        mmkv["min"] = Int.max
        XCTAssert(true, "Pass")
    }

    func testRead() {
        print(mmkv["b"] as Any)
        print(mmkv["i"] as Any)
        print(mmkv["i8"] as Any)
        print(mmkv["i16"] as Any)
        print(mmkv["i32"] as Any)
        print(mmkv["i64"] as Any)
        print(mmkv["u"] as Any)
        print(mmkv["u8"] as Any)
        print(mmkv["u16"] as Any)
        print(mmkv["u32"] as Any)
        print(mmkv["u64"] as Any)
        print(mmkv["f"] as Any)
        print(mmkv["d"] as Any)
        print(mmkv["f80"] as Any)
        print(mmkv["str"] as Any)
        print(mmkv["max"] as Any)
        print(mmkv["min"] as Any)

        XCTAssert(mmkv["b"] as? Int == 0)
        XCTAssert(mmkv["i"] as? Int == -1)
        XCTAssert(mmkv["i8"] as? Int == -8)
        XCTAssert(mmkv["i16"] as? Int == -16)
        XCTAssert(mmkv["i32"] as? Int == -32)
        XCTAssert(mmkv["i64"] as? Int == -64)
        XCTAssert(mmkv["u"] as? Int == 1)
        XCTAssert(mmkv["u8"] as? Int == 8)
        XCTAssert(mmkv["u16"] as? Int == 16)
        XCTAssert(mmkv["u32"] as? Int == 32)
        XCTAssert(mmkv["u64"] as? Int == 64)
        XCTAssert(mmkv["f"] as? Int == 11)
        XCTAssert(mmkv["d"] as? Int == 22)
        XCTAssert(mmkv["f80"] as? Int == 80)
        XCTAssert(mmkv["str"] as? String == "1000")
        XCTAssert(mmkv["max"] as? Int == Int.min)
        XCTAssert(mmkv["min"] as? Int == Int.max)
    }
}
