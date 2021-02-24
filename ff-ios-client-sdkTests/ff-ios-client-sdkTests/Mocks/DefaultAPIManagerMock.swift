//
//  File.swift
//  ff_ios_client_sdkTests
//
//  Created by Dusan Juranovic on 20.2.21..
//

import Foundation
@testable import ff_ios_client_sdk

class DefaultAPIManagerMock: DefaultAPIManagerProtocol {
	func getEvaluations(environmentUUID: String, target: String, apiResponseQueue: DispatchQueue, completion: @escaping (Swift.Result<[Evaluation], ff_ios_client_sdk.CFError>) -> ()) {
		if target == "success" {
			let evaluations = [Evaluation(flag: "someStringFlag", value: .string("string")),
							   Evaluation(flag: "someBoolFlag", value: .bool(true)),
							   Evaluation(flag: "someIntFlag", value: .int(1)),
							   Evaluation(flag: "someObjectFlag", value: .object(ValueType.Value(dictionaryLiteral: ("SomeTestKey", ValueType.bool(true))))),
							   Evaluation(flag: "someUnsupportedFlag", value: .unsupported)]
			completion(.success(evaluations))
		} else {
			completion(.failure(CFError.storageError))
		}
	}
	
	func getEvaluationByIdentifier(environmentUUID: String, feature: String, target: String, apiResponseQueue: DispatchQueue, completion: @escaping (Swift.Result<Evaluation, ff_ios_client_sdk.CFError>) -> ()) {
 		if feature == "success" {
			let evaluation = Evaluation(flag: "someFetchedFlag", value: .bool(false))
			completion(.success(evaluation))
		} else {
			completion(.failure(CFError.storageError))
		}
	}
	
	
}
