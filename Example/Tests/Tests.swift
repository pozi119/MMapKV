import XCTest
import MMapKV

class Tests: XCTestCase {
    lazy var mmapkv: MMapKV = {
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
        mmapkv["b"] = true
        mmapkv["i"] = Int.max
        mmapkv["i8"] = Int8.max
        mmapkv["i16"] = Int16.max
        mmapkv["i32"] = Int32.max
        mmapkv["i64"] = Int64.max
        mmapkv["u"] = UInt.max
        mmapkv["u8"] = UInt8.max
        mmapkv["u16"] = UInt16.max
        mmapkv["u32"] = UInt32.max
        mmapkv["u64"] = UInt64.max
        mmapkv["f"] = Float(11.011)
        mmapkv["d"] = Double(22.022)
        mmapkv["f80"] = Float80(33.033)
        mmapkv["str"] = "Hello world!"
        mmapkv["data"] = Data([0x1, 0x2, 0x3, 0x2, 0x1])
        mmapkv["date"] = Date()
    }
    
    func testRead() {
        let a = mmapkv["date"]
        let b = mmapkv["b"]
        let c = mmapkv["str"]
        print("\(String(describing: a)), \(String(describing: b)), \(String(describing: c))")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}

