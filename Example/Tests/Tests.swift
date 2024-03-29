import AnyCoder
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
        let a: UInt64 = 0xFFFFFFFFFFFFFFFF
        print(a.bytes)
        let bytes: [UInt8] = [255, 255, 255, 255, 255, 255, 255, 255]
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
        mmkv["max"] = Int.min
        mmkv["min"] = Int.max
        mmkv["string"] = "1000"
        mmkv["data"] = Data([13])
        mmkv["nsnumber"] = NSNumber(floatLiteral: 11.11)
        mmkv["nsstring"] = NSString(string: "2000")
        mmkv["nsdata"] = NSData(data: Data([11]))
        mmkv["cgfloat"] = CGFloat(22.22)
        mmkv["float"] = Float(11.11)
        mmkv["double"] = Double(33.33)
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
        print(mmkv["string"] as Any)
        print(mmkv["data"] as Any)
        print(mmkv["nsnumber"] as Any)
        print(mmkv["nsstring"] as Any)
        print(mmkv["nsdata"] as Any)
        print(mmkv["cgfloat"] as Any)
        print(mmkv["float"] as Any)
        print(mmkv["double"] as Any)

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
        XCTAssert(mmkv["max"] as? Int == Int.min)
        XCTAssert(mmkv["min"] as? Int == Int.max)
        XCTAssert(mmkv["string"] as? String == "1000")
        XCTAssert(mmkv["data"] as? Data == Data([13]))
        XCTAssert(mmkv["nsnumber"] as? NSNumber == NSNumber(floatLiteral: 11.11))
        XCTAssert(mmkv["nsstring"] as? NSString == NSString(string: "2000"))
        XCTAssert(mmkv["nsdata"] as? NSData == NSData(data: Data([11])))
        XCTAssert(mmkv["cgfloat"] as? CGFloat == CGFloat(22.22))
        XCTAssert(mmkv["float"] as? Float == Float(11.11))
        XCTAssert(mmkv["double"] as? Double == Double(33.33))
    }
}
