//
//  AuthenticationRequestTest.swift
//  ff_ios_client_sdkTests
//
//  Created by Dusan Juranovic on 16.2.21..
//

import XCTest
@testable import ff_ios_client_sdk

class AuthenticationRequestTest: XCTestCase {
    
	let cfClient = CFClient.sharedInstance
    override func setUp() {
        super.setUp()
		let mockAuthManager = AuthenticationManagerMock()
		let mockAPIManager = DefaultAPIManagerMock()
		let mockEventSourceManager = EventSourceManagerMock()
		
		cfClient.authenticationManager = mockAuthManager
		cfClient.eventSourceManager = mockEventSourceManager
		
		let repository = FeatureRepository(token: "someToken", storageSource: nil, config: nil, defaultAPIManager: mockAPIManager)
		cfClient.featureRepository = repository
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
	func testAuthorizationSuccess() {
		// Given
		let exp = XCTestExpectation(description: #function)
		let configuration = CFConfiguration.builder().setTarget("success").build()
		// When
		cfClient.initialize(apiKey: "someSuccessApiKey", configuration: configuration) { (result) in
			switch result {
				case .failure(let error):
					// Then
					XCTAssertNotNil(error)
					exp.fulfill()
				case .success():
					// Then
					XCTAssert(true)
					exp.fulfill()
			}
			self.wait(for: [exp], timeout: 5)
		}
	}
	
	func testAuthorizationFailure() {
		// Given
		let exp = XCTestExpectation(description: #function)
		let configuration = CFConfiguration.builder().setTarget("failure").build()
		// When
		cfClient.initialize(apiKey: "someFailureApiKey", configuration: configuration) { (result) in
			switch result {
				case .failure(let error):
					// Then
					XCTAssertNotNil(error)
					exp.fulfill()
				case .success:
					// Then
					XCTAssert(true)
					exp.fulfill()
			}
			self.wait(for: [exp], timeout: 5)
		}
	}
}
