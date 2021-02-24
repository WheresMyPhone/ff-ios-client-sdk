//
//  CFConfiguration.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 13.1.21..
//

import Foundation

/// `CFConfiguration` is `required` in order to initialize the SDK.
/// # Defaults: #
/// - `baseUrl`:  "http://34.82.119.242/api/1.0"
/// - `streamUrl`:  "http://34.82.119.242/api/1.0/stream/environments"
/// - `streamEnabled`: `false`
/// - `pollingInterval`: `60` seconds
/// - `target`: `""`
public struct CFConfiguration {
	var baseUrl: String
	var streamUrl: String
	var streamEnabled: Bool
	var pollingInterval: TimeInterval
	var environmentId: String
	var target: String
	
	internal init(baseUrl: String, streamUrl: String, streamEnabled: Bool, pollingInterval:TimeInterval, environmentId: String, target: String) {
		self.baseUrl = baseUrl
		self.streamUrl = streamUrl
		self.streamEnabled = streamEnabled
		self.pollingInterval = pollingInterval
		self.environmentId = environmentId
		self.target = target
	}
	
	public static func builder() -> CFConfigurationBuilder {
		return CFConfigurationBuilder()
	}
}

