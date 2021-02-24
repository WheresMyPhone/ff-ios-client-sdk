//
//  EventSourceManager.swift
//  
//
//  Created by Dusan Juranovic on 22.2.21..
//

import Foundation

protocol EventSourceManagerProtocol {
	static func shared(parameterConfig: ParameterConfig?) -> EventSourceManagerProtocol
	var parameterConfig: ParameterConfig? {get set}
	var configuration: CFConfiguration? {get set}
	var streamReady: Bool {get}
	func onOpen(_ completion:@escaping()->())
	func onComplete(_ completion:@escaping(Int?, Bool?, CFError?)->())
	func onMessage(_ completion:@escaping(String?, String?, String?)->())
	func addEventListener(_ event: String, completion:@escaping(String?, String?, String?)->())
	func connect(lastEventId: String?)
	func disconnect()
}

class EventSourceManager: EventSourceManagerProtocol {
	//MARK: - Internal properties -
	var streamReady: Bool {
		switch eventSource?.readyState {
			case .connecting, .open: return true
			default: return false
		}
	}
	
	var eventSource: EventSource?
	var configuration: CFConfiguration?
	var parameterConfig: ParameterConfig? {
		didSet {
			let config = self.configuration!
			if config.streamEnabled {
				self.eventSource = EventSource(url: URL(string: config.streamUrl)!
												.appendingPathComponent("/\(parameterConfig?.environmentId ?? "")"),
											   headers:parameterConfig?.authHeader ?? [:])
			} else {
				self.eventSource = nil
			}
		}
	}
	
	static func shared(parameterConfig: ParameterConfig? = nil) -> EventSourceManagerProtocol {
		return EventSourceManager()
	}
	
	//MARK: - Private methods -
	private init() {

	}
	
	//MARK: - Internal methods -
	func onOpen(_ completion:@escaping()->()) {
		eventSource?.onOpen {
			completion()
		}
	}
	
	func onComplete(_ completion:@escaping(Int?, Bool?, CFError?)->()) {
		eventSource?.onComplete({ (statusCode, retry, error) in
			guard error == nil else {
				if let code = (error as? URLError)?.code.rawValue {
					completion(statusCode, retry, CFError.streamError(.unableToConnect(.init(code: code))))
				}
				return
			}
			completion(statusCode, retry, nil)
		})
	}
	
	func onMessage(_ completion:@escaping(String?, String?, String?)->()) {
		eventSource?.onMessage({ (id, event, data) in
			completion(id, event, data)
		})
	}
	
	func addEventListener(_ event: String, completion:@escaping(String?, String?, String?)->()) {
		eventSource?.addEventListener(event, handler: { (id, event, data) in
			completion(id, event, data)
		})
	}
	
	func connect(lastEventId: String?) {
		eventSource?.connect(lastEventId: lastEventId)
	}
	func disconnect() {
		eventSource?.disconnect()
	}

}

struct ParameterConfig {
	let environmentId: String?
	let authHeader: [String:String]
}
