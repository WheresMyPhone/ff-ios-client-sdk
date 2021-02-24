//
//  NetworkInfoProvider.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 15.2.21..
//

import Foundation

class NetworkInfoProvider {
	private var reachability = try! Reachability()
	
	func networkStatus(_ completion:@escaping(Bool)->()) {
		reachability.whenReachable = { _ in
			completion(true)
		}
		
		reachability.whenUnreachable = { _ in
			completion(false)
		}
		
		do {
			try reachability.startNotifier()
		} catch {
			print("Unable to start notifier")
		}		
	}
}
