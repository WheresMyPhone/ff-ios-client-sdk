//
//  CFConfigurationBuilder.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 19.1.21..
//

import Foundation

public class CFConfigurationBuilder {
	var config : CFConfiguration!
	private let minimumPollingInterval:TimeInterval = 60
	
	public init(){
		self.config = CFConfiguration(baseUrl: CFConstants.Server.baseUrl,
									  streamUrl: CFConstants.Server.streamUrl,
									  streamEnabled: false,
									  pollingInterval: minimumPollingInterval,
									  environmentId: "",
									  target:"")
	}
	/**
	Adds `baseUrl` to CFConfiguration
	- Parameter baseUrl: `String`
	- Note: `build()` needs to be called as the final method in the chain
	*/
	public func setBaseUrl(_ baseUrl: String) -> CFConfigurationBuilder {
		config.baseUrl = baseUrl
		return self
	}
	/**
	Adds `streamUrl` to CFConfiguration
	- Parameter streamUrl: `String`
	- Note: `build()` needs to be called as the final method in the chain
	*/
	public func setStreamUrl(_ streamUrl: String) -> CFConfigurationBuilder {
		config.streamUrl = streamUrl
		return self
	}
	/**
	Adds `streamEnabled` flag  to CFConfiguration
	- Parameter isEnabled: `Bool`
	- Note: `build()` needs to be called as the final method in the chain
	*/
	public func setStreamEnabled(_ isEnabled: Bool) -> CFConfigurationBuilder {
		config.streamEnabled = isEnabled
		return self
	}
	/**
	Adds `pollingInterval`  to CFConfiguration
	- Parameter interval: `TimeInterval`. Minimum 60 seconds.
	- Note: `build()` needs to be called as the final method in the chain
	*/
	public func setPollingInterval(_ interval: TimeInterval) -> CFConfigurationBuilder {
		config.pollingInterval = interval < minimumPollingInterval ? minimumPollingInterval : interval
		return self
	}
	/**
	Adds `target`  to CFConfiguration
	- Parameter target: `String`
	- Note: `build()` needs to be called as the final method in the chain
	*/
	public func setTarget(_ target: String) -> CFConfigurationBuilder {
		config.target = target
		return self
	}
	/**
	Builds CFConfiguration object by providing components or is set to default component/s.
	- `setBaseUrl(_:)`
	- `setStreamUrl(_:)`
	- `setStreamEnabled(_:)`
	- `setPollingInterval(_:)`
	- `setTarget(_:)`
	
	# Defaults: #
	- `baseUrl`:  "http://34.82.119.242/api/1.0"
	- `streamUrl`:  "http://34.82.119.242/api/1.0/stream/environments"
	- `streamEnabled`: `false`
	- `pollingInterval`: `60` seconds
	- `target`: `""`
	*/
	public func build() -> CFConfiguration {
		return config
	}
}
