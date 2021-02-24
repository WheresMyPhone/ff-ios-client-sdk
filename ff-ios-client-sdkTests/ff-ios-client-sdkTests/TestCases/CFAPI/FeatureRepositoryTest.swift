//
//  FeatureRepositoryTest.swift
//  ff-ios-client-sdkTests
//
//  Created by Dusan Juranovic on 7.2.21..
//

import XCTest
@testable import ff_ios_client_sdk

class FeatureRepositoryTest: XCTestCase {
    
	var sut: FeatureRepository?
	
	var expectation: XCTestExpectation!
    override func setUp() {
        super.setUp()
		var config = CFConfiguration.builder().build()
		config.environmentId = "testEnvironment"
		sut = FeatureRepository(token: nil, storageSource: nil, config: config)
		sut!.defaultAPIManager = DefaultAPIManagerMock()
		expectation = XCTestExpectation(description: #function)
    }
    
    override func tearDown() {
		super.tearDown()
		
    }
    
    func testInitDefaultRepository() {
		// Given
		let token = "SomeTestToken"
		let config = CFConfiguration.builder().build()
		
		// When
		let defaultRepo = FeatureRepository(token: token, storageSource: nil, config: config)
		
		// Then
		XCTAssertEqual(defaultRepo.token, token)
		XCTAssertEqual(defaultRepo.config.baseUrl, config.baseUrl)
		XCTAssertEqual(defaultRepo.config.streamUrl, config.streamUrl)
		XCTAssertEqual(defaultRepo.config.environmentId, config.environmentId)
		XCTAssertEqual(defaultRepo.config.target, config.target)
		XCTAssertEqual(defaultRepo.config.pollingInterval, config.pollingInterval)
		XCTAssertEqual(defaultRepo.config.streamEnabled, config.streamEnabled)
		XCTAssertNotNil(defaultRepo.storageSource)
    }
    
    func testGetEvaluationSuccess() {
		// Given
		sut?.config.target = "success"
		
		// When
		let result = await(sut!.getEvaluations(onCompletion:))
		
		// Then
		XCTAssertNotNil(result)
		XCTAssertEqual(result?.count, 5, "Expected count == 5")
    }
	
	func testGetEvaluationFailure() {
		// Given
		sut?.config.target = "failure"
		
		// When
		let result = await(sut!.getEvaluations(onCompletion:))
		
		// Then
		XCTAssertNil(result)
	}
	
	func testGetEvaluationByIdSuccess() {
		// Given
		let operation = sut
		
		// When
		operation?.getEvaluationbyId("success", onCompletion: { (result) in
			switch result {
				case .failure(let error):
					// Then
					XCTAssertNotNil(error)
				case .success(let evaluation):
					// Then
					XCTAssertNotNil(evaluation)
					XCTAssertEqual(evaluation.flag, "someFetchedFlag")
					XCTAssertEqual(evaluation.value.boolValue, false)
			}
		})
	}
	
	func testGetEvaluationByIdFailure() {
		// Given
		let operation = sut
		
		// When
		operation?.getEvaluationbyId("failure", onCompletion: { (result) in
			switch result {
				case .failure(let error):
					// Then
					XCTAssertNotNil(error)
				case .success(let evaluation):
					// Then
					XCTAssertNotNil(evaluation)
					XCTAssertEqual(evaluation.flag, "someFetchedFlag")
					XCTAssertEqual(evaluation.value.boolValue, false)
			}
		})
	}
}
