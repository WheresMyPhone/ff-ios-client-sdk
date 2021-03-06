# ff-ios-client-sdk overview - WheresMyPhoneClone

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)

---
[Harness](https://www.harness.io/) is a feature management platform that helps teams to build better software and enable features faster.
&nbsp;
# _Installing the `ff-ios-client-sdk`_
Installing ff-ios-client-sdk is possible with `Swift Package Manager (SPM)`

TO BE ADDED: `CocoaPods` and `Carthage`

&nbsp;
## <u>_Swift Package Manager (SPM)_</u>
The [Swift Package Manager](https://swift.org/package-manager/) is a dependency manager integrated into the `swift` compiler and `Xcode`.

To integrate `ff-ios-client-sdk` into an Xcode project, go to the project editor, and select `Swift Packages`. From here hit the `+` button and follow the prompts using  `https://github.com/wings-software/ff-ios-client-sdk.git` as the URL.

To include `ff-ios-client-sdk` in a Swift package, simply add it to the dependencies section of your `Package.swift` file. And add the product "HarnessSDKiOS" as a dependency for your targets.

```Swift
dependencies: [
	.package(url: "https://github.com/wings-software/ff-ios-client-sdk.git", .upToNextMinor(from: "1.0.7"))
]
```
&nbsp;
## <u>_CocoaPods -> TO BE ADDED_</u>
&nbsp;
## <u>_Carthage -> TO BE ADDED_</u>

&nbsp;
# _Using the `ff-ios-client-sdk`_

In order to use `ff-ios-client-sdk` in your application, there are a few steps that you would need to take.

## **_Initialization_**
1. Setup your configuration by calling `CFConfiguration`'s static method `builder()` and pass-in your prefered configuration settings through possible chaining methods. The chaining needs to be ended with `build()` method. (See the `build()`'s description for possible chaining methods and their default values.)

2. Call `CFClient.sharedInstance.initialize(apiKey:configuration:cache:onCompletion:)` and pass in your Harness CF `apiKey`, previously created configuration object and an optional cache object adopting `StorageRepositoryProtocol`.
	(If cache object is not specified, internal built-in cache will be used.)

**Your `ff-ios-client-sdk` is now initialized. Congratulations!!!**

&nbsp;
Upon successful initialization and authorization, the completion block of `CFClient.sharedInstance.initialize(apiKey:configuration:cache:onCompletion:)` will deliver `Swift.Result<Void, CFError>` object. You can then switch through it's `.success(Void)` and `.failure(CFError)` cases and decide on further steps depending on a result.

_Code example:_
```Swift
let configuration = CFConfiguration.builder().setStreamEnabled(true).setTarget("HarnessSDKTestTarget").build()
CFClient.sharedInstance.initialize(apiKey: "YOUR-API-KEY", configuration: configuration) { (result) in
	switch result {
		case .failure(let error):
			//Do something to gracefully handle initialization/authorization failure
		case .success:
			//Continue to the next step after successful initialization/authorization  
	}
}
```
&nbsp;
## **_Implementation_**
The Public API exposes two methods that you should utilize:

* `public func initialize(apiKey:configuration:cache:onCompletion:)` -> Called first as described above in the **_initialization_** section.

* `public func registerEventsListener(_ events:onCompletion:)` -> Called in the ViewController where you would like to receive the events.

&nbsp;
### <u>_registerEventsListener(_ events:onCompletion:)_</u>
`events` is an array of events that you would like to subscribe to. It defaults to `*`, which means ALL events. 
In order to be notified of the SSE events sent from the server, you need to call `CFClient.sharedInstance.registerEventsListener()` method 

<u style="color:red">**NOTE**</u>: Registering to events is usually done in `viewDidLoad()` method when events are required in only one ViewController _OR_ `viewDidAppear()` if there are more than one registration calls throughout the app, so the events could be re-registered for the currently visible ViewController.

The completion block of this method will deliver `Swift.Result<EventType, CFError>` object. You can use `switch` statement within it's `.success(EventType)` case to distinguish which event has been received and act accordingly as in the example below or handle the error gracefully from it's `.failure(CFError)` case.

_Code example:_
```Swift
CFClient.sharedInstance.registerEventsListener() { (result) in
	switch result {
		case .failure(let error):
			//Gracefully handle error
		case .success(let eventType):
			switch eventType {
				case .onPolling(let evaluations):
					//Received all evaluation flags -> [Evaluation]
				case .onEventListener(let evaluation):
					//Received an evaluation flag -> Evaluation
				case .onComplete:
					//Received a completion event, meaning that the 
					//SSE has been disconnected
				case .onOpen(_):
					//SSE connection has been established and is active
				case .onMessage(let messageObj):
					//An empty Message object has been received
			}
		}
	}
}
```
