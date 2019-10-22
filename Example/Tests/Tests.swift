import MMapKV
import XCTest

class Tests: XCTestCase {
    lazy var mmkv = MMKV<String, Int>()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testWrite() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
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
        mmkv["str"] = 1000
        mmkv["max"] = Int.min
        mmkv["min"] = Int.max
    }

    func testRead() {
        XCTAssert(mmkv["b"] == 0)
        XCTAssert(mmkv["i"] == -1)
        XCTAssert(mmkv["i8"] == -8)
        XCTAssert(mmkv["i16"] == -16)
        XCTAssert(mmkv["i32"] == -32)
        XCTAssert(mmkv["i64"] == -64)
        XCTAssert(mmkv["u"] == 1)
        XCTAssert(mmkv["u8"] == 8)
        XCTAssert(mmkv["u16"] == 16)
        XCTAssert(mmkv["u32"] == 32)
        XCTAssert(mmkv["u64"] == 64)
        XCTAssert(mmkv["f"] == 11)
        XCTAssert(mmkv["d"] == 22)
        XCTAssert(mmkv["f80"] == 80)
        XCTAssert(mmkv["str"] == 1000)
        XCTAssert(mmkv["max"] == Int.min)
        XCTAssert(mmkv["min"] == Int.max)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
