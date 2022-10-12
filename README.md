# MMapKV

[![CI Status](https://img.shields.io/travis/pozi119/MMapKV.svg?style=flat)](https://travis-ci.org/pozi119/MMapKV)
[![Version](https://img.shields.io/cocoapods/v/MMapKV.svg?style=flat)](https://cocoapods.org/pods/MMapKV)
[![License](https://img.shields.io/cocoapods/l/MMapKV.svg?style=flat)](https://cocoapods.org/pods/MMapKV)
[![Platform](https://img.shields.io/cocoapods/p/MMapKV.svg?style=flat)](https://cocoapods.org/pods/MMapKV)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MMapKV is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MMapKV', '~> 0.1.1'
pod 'Runtime', :git => 'https://github.com/wickwirew/Runtime.git' // The version in pods is 2.2.2, which requires 2.2.4
```

## Change(0.1.1)
1. 不在使用泛型，Key使用String类型，Value使用AnyCoder定义的Primitive类型；不再支持复杂对象。
2. 添加didUpdate回调。

## Author

pozi119, pozi119@163.com

## License

MMapKV is available under the MIT license. See the LICENSE file for more info.
