//
//  CFClient.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 13.1.21..
//

import Foundation
///An enum with associated values,  representing possible event types.
/// - `case` onOpen(`String`)
/// - `case` onComplete
/// - `case` onMessage(`Message?`)
/// - `case` onEventListener(`Evaluation?`)
/// - `case` onPolling(`[Evaluation]?`)
public enum EventType: Equatable {
	///Returns only a `String` message that the SSE has been opened
	case onOpen
	///Returns  a `String` message that the SSE has beeen completed.
	case onComplete
	///Returns an empty `Message` object.
	case onMessage(Message?)
	///Returns one `Evaluation?` requested upon received event from the SSE server.
	case onEventListener(Evaluation?)
	///Returns  `[Evaluation]?` on initialization and after SSE has been established.
	case onPolling([Evaluation]?)
	
	enum ComparableType: String {
		case onOpen
		case onComplete
		case onMessage
		case onEventListener
		case onPolling
	}
	
	var comparableType: ComparableType {
		switch self {
			case .onOpen: 			return .onOpen
			case .onComplete: 		return .onComplete
			case .onMessage: 		return .onMessage
			case .onEventListener: 	return .onEventListener
			case .onPolling: 		return .onPolling
		}
	}
	
	static public func ==(lhs: EventType, rhs: EventType) -> Bool {
		return lhs.comparableType.rawValue == rhs.comparableType.rawValue
	}
}

public class CFClient {
	//MARK: - Private properties -
	private enum State {
		case onlineStreaming
		case onlinePolling
		case offline
	}
	
	private init(authenticationManager: AuthenticationManagerProtocol = AuthenticationManager()){
		self.authenticationManager = authenticationManager
		self.eventSourceManager = EventSourceManager.shared()
	}
	
	private var onPollingResultCallback: ((Swift.Result<EventType, CFError>) -> ())?
	private var lastEventId:String?
	
	///Cache and Storage provider used for in-memory and disk storage.
	///- Defaults to `CFCache` if custom provider is not specified during CFClient initialization.
	///- All providers must adopt `StorageRepositoryProtocol` in order to qualify.
	private var storageSource: StorageRepositoryProtocol?
	
	///JWT received after successfull authentication.
	/// - contains:
	///		- `header`
	///		- `authToken`
	///		- `signature`
	///separated by a `dot` (`.`)
	private var token: String?
	private var timer: Timer?
	
	///Provides network state
	lazy private var networkInfoProvider = NetworkInfoProvider()
	private var pollingEnabled: Bool = true
	
	//MARK: - Internal properties -
	var configuration:CFConfiguration!
	var authenticationManager: AuthenticationManagerProtocol!
	var eventSourceManager: EventSourceManagerProtocol!
	
	///Used for cloud communication
	///Lazily instantiated during CFClient `initialize(clientID:config:cache:)` call, after it's dependencies are set.
	lazy var featureRepository = FeatureRepository(token: self.token, storageSource: self.storageSource, config: self.configuration)
	
	//MARK: - Public properties -
	public static var sharedInstance = CFClient()
	
	///This flag determines if the `authToken` has been received, indicating that the Authorization has been successful.
	public var isInitialized: Bool = false
	
	//MARK: - Public methods -
	///This method need to be run first, to initiate authorization.
	/// - Parameters:
	///   - clientId: `Client ID` / `apiKey`
	///   - config: `CFConfiguration` to be used for Evaluation fetching
	///   - cache: `StorageRepositoryProtocol`. Defaults to CFCache
	/// - NOTE: In order to use your own cache, you need to wrap your caching solution into a wrapper, that adopts `StorageRepositoryProtocol`.
	public func initialize(apiKey: String, configuration: CFConfiguration, cache: StorageRepositoryProtocol = CFCache(), onCompletion:@escaping(Swift.Result<Void, CFError>)->()) {
		self.configuration = configuration
		let authRequest = AuthenticationRequest(apiKey: apiKey)
		self.authenticate(authRequest, cache: cache) { (response) in
			switch response {
				case .failure(let error):
					onCompletion(.failure(error))
				case .success(_):
					onCompletion(.success(()))
			}
		}
	}
	
	/// Initializes authentication and fetches initial Evaluations from the cloud, after successful  authorization.
	/// - Parameters:
	///   - authRequest: `apiKey`
	///   - cache: Cache to be used. Defaults to internal `CFCache`.
	///   - onCompletion: Completion block containing `Swift.Result<AuthenticationResponse, CFError>?`
	private func authenticate(_ authRequest: AuthenticationRequest, cache: StorageRepositoryProtocol, onCompletion:@escaping(Swift.Result<Void, CFError>)->()) {
		authenticationManager.authenticate(authenticationRequest: authRequest, apiResponseQueue: .main) { (response, error) in
			guard error == nil else {
				onCompletion(.failure(error!))
				self.isInitialized = false
				Logger.log("AUTHENTICATION FAILURE")
				return
			}
			Logger.log("AUTHENTICATION SUCCESS")
			
			//Set storage to provided cache or CFCache by default
			self.storageSource = cache
			
			//Extract info from retrieved JWT
			let dict = JWTDecoder().decode(jwtToken: response!.authToken)
			let project = CFProject(dict:dict ?? [:])
			self.isInitialized = true
			self.configuration.environmentId = project.environment
			self.token = response!.authToken
			
			//Assign retrieved values to lazily instantiated `featureRepository`
			self.featureRepository.token = self.token!
			self.featureRepository.storageSource = self.storageSource!
			self.featureRepository.config = self.configuration
			
//			//Initialize NetworkInfoProvider(), once authorization is successful
//			self.networkInfoProvider = NetworkInfoProvider()
			
			//Initial getEvaluations to be stored in cache
			self.featureRepository.getEvaluations(onCompletion: { (result) in
				let allKey = CFConstants.Persistance.features(self.configuration.environmentId, self.configuration.target).value
				switch result {
					case .success(let evaluations):
						do {
							try self.storageSource?.saveValue(evaluations, key: allKey)
							onCompletion(.success(()))
						} catch {
							print("Could not save to cache")
						}
					case .failure(_):
						//Failed to initialy fetch evaluations. Ignore this error
						break
				}
			})
		}
	}
	
	///Completion block of this method will be called on each SSE response event.
	///This method needs to be called in order to get SSE events.
	/// - Parameters:
	///	  - events: An optional `[String]?`, representing the Events we want to subscribe to. Defaults to `[*]`, which subscribes to all events.
	///   - onCompletion: Completion block containing `Swift.Result<EventType, CFError>`
	///   - eventType: An enum with associated values, representing possible event types
	///   	 - `case` onOpen(`String`)
	/// 	 - `case` onComplete
	/// 	 - `case` onMessage(`Message?`)
	/// 	 - `case` onEventListener(`Evaluation?`)
	/// 	 - `case` onPolling(`[Evaluation]?`)
	///   - error: A `CFError`
	public func registerEventsListener(_ events:[String] = ["*"], onCompletion:@escaping(Swift.Result<EventType, CFError>)->()) {
		let allKey = CFConstants.Persistance.features(self.configuration.environmentId, self.configuration.target).value
		do {
			let initialEvaluations: [Evaluation]? = try self.featureRepository.storageSource.getValue(forKey: allKey)
			onCompletion(.success(EventType.onPolling(initialEvaluations)))
		} catch {
			print("Could not fetch from cache")
		}
		if self.configuration.streamEnabled {
			let parameterConfig = ParameterConfig(environmentId: self.configuration.environmentId, authHeader: [CFHTTPHeaderField.authorization.rawValue:"Bearer \(self.token ?? "")"])
			guard self.eventSourceManager != nil else {
				return onCompletion(.failure(CFError.streamError(StreamError.couldNotCreateCFEventSourceInstance)))
			}
			self.eventSourceManager.configuration = self.configuration
			self.eventSourceManager.parameterConfig = parameterConfig
			startStream(events) { (startStreamResult) in
				switch startStreamResult {
					case .failure(let error):
						onCompletion(.failure(error))
					case .success(let eventType):
					onCompletion(.success(eventType))
				}
			}
		} else {
			self.setupFlowFor(.onlinePolling)
		}
		self.onPollingResultCallback = {(result) in
			switch result {
				case .failure(let error):
					onCompletion(.failure(error))
				case .success(let eventType):
					onCompletion(.success(eventType))
			}
		}
		self.registerForNetworkConditionNotifications()
	}
	
	///Connect to the SSE stream if the stream is ready OR continue with already connected stream.
	func connectStream() {
		guard let stream = eventSourceManager else { return }
		if !stream.streamReady {
			stream.connect(lastEventId: self.lastEventId)
		}
	}
	
	///Disconnects the SSE stream.
	func disconnectStream() {
		guard let stream = eventSourceManager else { return }
		stream.disconnect()
	}
	
	//MARK: - Private methods -
	private func setupFlowFor(_ state: State) {
		switch state {
			case .offline:
				self.stopPolling()
				self.disconnectStream()
			case .onlinePolling:
				self.disconnectStream()
				if self.pollingEnabled {
					self.startPolling { (result) in
						switch result {
							case .failure(let error):
								self.onPollingResultCallback?(.failure(error))
							case .success(let eventType):
								self.onPollingResultCallback?(.success(eventType))
						}
					}
				}
			case .onlineStreaming:
				self.stopPolling()
				self.startStreaming()
		}
	}
	
	private func registerForNetworkConditionNotifications() {
		self.networkInfoProvider.networkStatus { (isOnline) in
			self.pollingEnabled = isOnline
			if isOnline {
				if self.configuration.streamEnabled {
					self.setupFlowFor(.onlineStreaming)
				}
				Logger.log("Polling ENABLED due to NETWORK AVAILABLE")
			} else {
				self.setupFlowFor(.offline)
				Logger.log("Polling/Streaming DISABLED due to NO NETWORK")
			}
		}
	}
	
	//MARK: STREAMING
	/// Initiates SSE listening
	/// - Parameters:
	///   - events: Optional `[String]`
	///   - onCompletion: completion block containing `Swift.Result<EventType, CFError>`
	private func startStream(_ events:[String], onCompletion:@escaping(Swift.Result<EventType, CFError>)->()) {
		let stream = eventSourceManager!
		registerStreamCallbacks(from: stream, environmentId: self.configuration!.environmentId, events: events) { (eventType, error) in
			guard error == nil else {
				onCompletion(.failure(error!))
				return
			}
			onCompletion(.success(eventType))
		}
	}
	
	private func registerStreamCallbacks(from eventSource:EventSourceManagerProtocol, environmentId: String, events:[String], onEvent:@escaping(EventType, CFError?)->()) {
		//ON OPEN
		eventSource.onOpen() {
			Logger.log("SSE connection has been opened")
			onEvent(EventType.onOpen, nil)
			self.featureRepository.getEvaluations(onCompletion: { (result) in
				switch result {
					case .success(let evaluations):
						onEvent(EventType.onPolling(evaluations), nil)
					case .failure(_):
						//If error occurs while fetching evaluations, we just ignore this failure and continue with SSE.
						break
				}
			})
			self.setupFlowFor(.onlineStreaming)
		}
		
		//ON COMPLETE
		eventSource.onComplete() {(statusCode, retry, error) in
			self.setupFlowFor(.onlinePolling)
			guard error == nil else {
				onEvent(EventType.onComplete, error)
				return
			}
			onEvent(EventType.onComplete, nil)
		}
		
		//ON MESSAGE
		eventSource.onMessage() {(id, event, data) in
			print("Got message with empty data \(Date())")
			guard let stringData = data else {
				onEvent(EventType.onMessage(Message(event: "message", domain: "", identifier: "", version: 0)), nil)
				return
			}
			do {
				let data = stringData.data(using: .utf8)
				let decoded = try JSONDecoder().decode(Message.self, from: data!)
				onEvent(EventType.onMessage(decoded), nil)
			} catch {
				onEvent(EventType.onMessage(nil), CFError.parsingError)
			}
		}
		
		for event in events {
			//ON EVENT
			eventSource.addEventListener(event) { (id, event, data) in
				Logger.log("An Event has been received")
				guard let stringData = data else {
					onEvent(EventType.onEventListener(nil), CFError.noDataError)
					return
				}
				do {
					let data = stringData.data(using: .utf8)
					let decoded = try JSONDecoder().decode(Message.self, from: data!)
					self.lastEventId = decoded.event
					self.featureRepository.getEvaluationbyId(decoded.identifier ?? "", onCompletion: { (result) in
						switch result {
							case .failure(let error): onEvent(EventType.onEventListener(nil), error)
							case .success(let evaluation): onEvent(EventType.onEventListener(evaluation), nil)
						}
					})
				} catch {
					onEvent(EventType.onEventListener(nil), CFError.parsingError)
				}
			}
		}
	}
	
	//MARK: STREAMING/POLLING SWITCH METHODS
	private func startStreaming(_ events:[String]? = nil) {
		Logger.log("POLLING stopped / STREAM starting")
		self.connectStream()
	}
	
	private func stopPolling() {
		if timer != nil {
			timer?.invalidate()
			timer = nil
		}
	}
	
	private func startPolling(onCompletion:@escaping(Swift.Result<EventType, CFError>)->()) {
		Logger.log("Try reconnecting to STREAM with retry interval of \(self.configuration.pollingInterval) seconds")
		timer = Timer.scheduledTimer(withTimeInterval: self.configuration.pollingInterval, repeats: true) { _ in
			if self.configuration.streamEnabled {
				self.setupFlowFor(.onlineStreaming)
			}
			self.featureRepository.getEvaluations() { (result) in
				switch result {
					case .failure(let error):
						onCompletion(.failure(error))
					case .success(let evaluations):
						onCompletion(.success(EventType.onPolling(evaluations)))
				}
			}
		}
	}
}
