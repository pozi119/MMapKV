import MMapKV
import XCTest

class Tests: XCTestCase {
    lazy var mmapkv: MMapKV<String, Int> = {
        MMapKV()
    }()

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
        mmapkv["b"] = 0
        mmapkv["i"] = -1
        mmapkv["i8"] = -8
        mmapkv["i16"] = -16
        mmapkv["i32"] = -32
        mmapkv["i64"] = -64
        mmapkv["u"] = 1
        mmapkv["u8"] = 8
        mmapkv["u16"] = 16
        mmapkv["u32"] = 32
        mmapkv["u64"] = 64
        mmapkv["f"] = 11
        mmapkv["d"] = 22
        mmapkv["f80"] = 80
        mmapkv["str"] = 1000
        mmapkv["max"] = Int.min
        mmapkv["min"] = Int.max
    }

    func testRead() {
        let a = mmapkv["i"]
        let b = mmapkv["max"]
        let c = mmapkv["min"]
        print("\(String(describing: a)), \(String(describing: b)), \(String(describing: c))")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
