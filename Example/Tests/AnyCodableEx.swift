//
//  AnyCodableEx.swift
//  MMapKV_Tests
//
//  Created by Valo on 2019/10/23.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AnyCodable
import Foundation

extension AnyCodable: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(nil)
    }
}

extension AnyCodable: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Float
    public init(floatLiteral value: Float) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = AnyCodable
    public init(arrayLiteral elements: AnyCodable...) {
        self.init(elements)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = AnyCodable
    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        var dic = [String: AnyCodable]()
        for element in elements {
            dic[element.0] = element.1
        }
        self.init(dic)
    }
}
