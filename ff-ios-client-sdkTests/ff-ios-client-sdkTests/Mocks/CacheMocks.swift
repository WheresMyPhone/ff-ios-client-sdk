//
//  CacheMocks.swift
//  ff_ios_client_sdkTests
//
//  Created by Dusan Juranovic on 2.2.21..
//

import Foundation
@testable import ff_ios_client_sdk

struct CacheMocks {
	enum TestFlagValue {
		case string(ValueType)
		case bool(ValueType)
		case int(ValueType)
		case object(ValueType)
		case unsupported(ValueType)
		
		enum RawValue: Int, CaseIterable {
			case string
			case bool
			case int
			case object
			case unsupported
		}
		
		init(_ rawValue: RawValue) {
			switch rawValue {
				case .string: self = .string(.string("SomeRandomString"))
				case .bool: self = .bool(.bool(true))
				case .int: self = .int(.int(5))
				case .object: self = .object(.object(["randomKey":.string("RandomValue")]))
				case .unsupported: self = .unsupported(.unsupported)
			}
		}
		
		var value: ValueType {
			switch self {
				case .string(let val): return val
				case .bool(let val): return val
				case .int(let val): return val
				case .object(let val): return val
				case .unsupported(let val): return val
			}
		}
	}
    static func createFlagMocks(count: Int) -> [Evaluation]  {
		var mocks = [Evaluation]()
		for _ in 0..<count  {
			let random = Int(arc4random_uniform(UInt32(TestFlagValue.RawValue.allCases.count)))
			let randomValueType = TestFlagValue(TestFlagValue.RawValue(rawValue: random)!)
			mocks.append(.init(flag: UUID().uuidString, value: randomValueType.value))
		}
        return mocks
    }
	
	static func createAllTypeFlagMocks() -> [Evaluation]  {
		var mocks = [Evaluation]()
		while mocks.count != 5 {
			let random = Int(arc4random_uniform(UInt32(TestFlagValue.RawValue.allCases.count)))
			let randomValueType = TestFlagValue(TestFlagValue.RawValue(rawValue: random)!)
			if !mocks.contains(where: {$0.value == randomValueType.value}) {
				mocks.append(.init(flag: UUID().uuidString, value: randomValueType.value))
			}
		}
		return mocks
	}
}


