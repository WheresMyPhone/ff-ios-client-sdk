//
//  CFConstants.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 14.1.21..
//

import Foundation

enum CFHTTPHeaderField: String
{
	case authorization  = "Authorization"
	case contentType    = "Content-Type"
	case acceptType     = "Accept"
	case acceptEncoding = "Accept-Encoding"
	case cacheControl	= "Cache-Control"
}

enum CFContentType: String
{
	case json = "application/json"
	case form = "application/x-www-form-urlencoded"
	case eventStream = "text/event-stream"
	case noCache = "no-cache"
	case textHtml = "text/html"
}

enum CFEndpoints: String {
	case auth = "/auth"
	case env  = "/env"
}

enum CFHTTPMethod: String {
	case get = "GET"
	case post = "POST"
}

struct CFConstants
{
	enum Persistance {
		case feature(String, String, String)
		case features(String, String)
		
		var value: String {
			switch self {
				case let .feature(envId, target , feature): return "\(envId)_\(target)_\(feature)"
				case let .features(envId, target): return "\(envId)_\(target)_features"
			}
		}
	}
	struct Server
	{
		static let baseUrl 	 = "https://cf-stream.uat.harness.io/api/1.0"
		static let streamUrl = "https://cf-stream.uat.harness.io/api/1.0/stream/environments"
	}
	
	struct ParamKey
	{
		static let authToken = "authToken"
	}
}
