//
//  RegisterForEventsTest.swift
//  ff-ios-client-sdkTests
//
//  Created by Dusan Juranovic on 20.2.21..
//

import XCTest
@testable import ff_ios_client_sdk

class RegisterForEventsTest: XCTestCase {
	
	let cfClient = CFClient.sharedInstance
	override func setUp() {
		super.setUp()
		let authManager = AuthenticationManagerMock()
		cfClient.authenticationManager = authManager
		
		var config = CFConfiguration.builder().build()
		config.environmentId = "someId"
		
		let defaultAPIManager = DefaultAPIManagerMock()
		let repository = FeatureRepository(token: "someToken", storageSource: nil, config: config, defaultAPIManager: defaultAPIManager)

		cfClient.featureRepository = repository
		cfClient.configuration = config
		
		cfClient.eventSourceManager = EventSourceManagerMock.shared()
	}
	
	override func tearDown() {
		super.tearDown()
//		cfClient.configuration = nil
//		cfClient.featureRepository = nil
	}
	
	func testRegisterForEventsFailure() {
		var config = CFConfiguration.builder().setStreamEnabled(true).setTarget("failure").build()
		config.environmentId = "failID"
		cfClient.configuration = config
		cfClient.eventSourceManager = nil
		cfClient.registerEventsListener { (result) in
			switch result {
				case .failure(let error):
					XCTAssertNotNil(error)
				case .success(let eventType):
					XCTAssertNotNil(eventType)
			}
		}
	}
	
	func testRegisterForEventsSuccess() {
		var config = CFConfiguration.builder().setStreamEnabled(true).setTarget("success").build()
		let eval = Evaluation(flag: "testRegisterEventSuccessFlag", value: .bool(true))
		try? cfClient.featureRepository.storageSource.saveValue(eval, key: "SODOD")
		config.environmentId = "successID"
		cfClient.configuration = config
		
		let exp = XCTestExpectation(description: #function)
		cfClient.registerEventsListener(["event-success"]) { (result) in
			switch result {
				case .failure(let error):
					XCTAssertNotNil(error)
					exp.fulfill()
				case .success(let eventType):
					switch eventType {
						case .onOpen:
							XCTAssertEqual(eventType, EventType.onOpen)
							exp.fulfill()
						case .onComplete:
							XCTAssertEqual(eventType, EventType.onComplete)
							exp.fulfill()
						case .onMessage:
							XCTAssertEqual(eventType.comparableType, EventType.ComparableType.onMessage)
							exp.fulfill()
						case .onPolling:
							XCTAssertEqual(eventType.comparableType, EventType.ComparableType.onPolling)
							exp.fulfill()
						case .onEventListener:
							XCTAssertEqual(eventType.comparableType, EventType.ComparableType.onEventListener)
							exp.fulfill()
					}
			}
		}
		
		wait(for: [exp], timeout: 5)
	}
	
	func testRegisterEventsManagerNil() {
		var config = CFConfiguration.builder().setStreamEnabled(true).build()
		config.environmentId = "successID"
		cfClient.configuration = config
		cfClient.eventSourceManager = nil
		cfClient.registerEventsListener { (result) in
			switch result {
				case .failure(let error):
					XCTAssertNotNil(error)
				case .success(let eventType):
					XCTAssertNotNil(eventType)
			}
		}
	}
}
