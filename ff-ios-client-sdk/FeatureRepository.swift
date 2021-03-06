//
//  FeatureRepository.swift
//  CFiOSClient
//
//  Created by Dusan Juranovic on 2.2.21..
//

import Foundation
class FeatureRepository {
	var token: String
	var storageSource: StorageRepositoryProtocol
	var config:CFConfiguration
	var defaultAPIManager: DefaultAPIManagerProtocol!
	
	init(token: String?, storageSource: StorageRepositoryProtocol?, config:CFConfiguration?, defaultAPIManager: DefaultAPIManagerProtocol = DefaultAPIManager()) {
		self.token = token ?? ""
		self.storageSource = storageSource ?? CFCache()
		self.config = config ?? CFConfiguration.builder().build()
		self.defaultAPIManager = defaultAPIManager
	}
	
	/// Use this method to get `[Evaluation]` for a  target specified in `CFConfiguration` during the call to initialize `CFClient`.
	/// - Parameters:
	///   - onCompletion: completion block containing `[Evaluation]?` or `CFError?` from appropriate lower level methods.
	func getEvaluations(onCompletion:@escaping(Result<[Evaluation], CFError>)->()) {
		OpenAPIClientAPI.customHeaders = [CFHTTPHeaderField.authorization.rawValue:"Bearer \(self.token)"]
		
		Logger.log("Try to get ALL from CLOUD")
		defaultAPIManager.getEvaluations(environmentUUID: self.config.environmentId, target: self.config.target, apiResponseQueue: .main) { (result) in
			let allKey = CFConstants.Persistance.features(self.config.environmentId, self.config.target).value
			switch result {
				case .failure(let error):
					Logger.log("Failed getting ALL from CLOUD. Try CACHE/STORAGE")
					do {
						let evals: [Evaluation]? = try self.storageSource.getValue(forKey: allKey)
						onCompletion(.success(evals ?? []))
						Logger.log("SUCCESS: Got ALL from CACHE/STORAGE")
					} catch {
						Logger.log("FAILURE: Unable to get ALL from CACHE/STORAGE")
						onCompletion(.failure(CFError.storageError))
					}
				case .success(let evaluations):
					Logger.log("SUCCESS: Got ALL from CLOUD")
					
					for eval in evaluations {
						let key = CFConstants.Persistance.feature(self.config.environmentId, self.config.target, eval.flag).value
						do {
							try self.storageSource.saveValue(eval, key: key)
						} catch {
							onCompletion(.failure(CFError.storageError))
						}
					}
					do {
						try self.storageSource.saveValue(evaluations, key: allKey)
					} catch {
						onCompletion(.failure(CFError.storageError))
					}
					onCompletion(.success(evaluations))
			}
		}
	}
	
	/// Use this method to get `Evaluation`for a  target specified in `CFConfiguration` during the call to initialize `CFClient`.
	/// - Parameters:
	///   - feature: `Feature ID`
	///   - onCompletion: completion block containing `Evaluation?` or `CFError?` from appropriate lower level methods.
	func getEvaluationbyId(_ evaluationId: String, onCompletion:@escaping(Result<Evaluation, CFError>)->()) {
		OpenAPIClientAPI.customHeaders = [CFHTTPHeaderField.authorization.rawValue:"Bearer \(self.token)"]
		Logger.log("Try to get Evaluation |\(evaluationId)| from CLOUD")
		defaultAPIManager.getEvaluationByIdentifier(environmentUUID: self.config.environmentId, feature: evaluationId, target: self.config.target, apiResponseQueue: .main) { (result) in
			let key = CFConstants.Persistance.feature(self.config.environmentId, self.config.target, evaluationId).value
			switch result {
				case .failure(let error):
					Logger.log("Failed getting |\(evaluationId)| from CLOUD. Try CACHE/STORAGE")
					do {
						if let storedFeature: Evaluation? = try self.storageSource.getValue(forKey: key) {
							onCompletion(.success(storedFeature!))
							Logger.log("SUCCESS: Got |\(evaluationId)| -> |\(storedFeature!.value)| from CACHE/STORAGE")
						} else {
							Logger.log("FAILURE: Unable to get |\(evaluationId)| from CACHE/STORAGE")
							onCompletion(.failure(CFError.noDataError))
						}
					} catch {
						onCompletion(.failure(CFError.noDataError))
					}
				case .success(let evaluation):
					Logger.log("SUCCESS: Got |\(evaluationId)| -> |\(evaluation.value)| from CLOUD")
					do {
						try self.storageSource.saveValue(evaluation, key: key)
						self.updateAll(evaluation)
					} catch {
						onCompletion(.failure(CFError.storageError))
					}
					onCompletion(.success(evaluation))
			}
		}
	}
	
	private func updateAll(_ eval: Evaluation) {
		let allKey = CFConstants.Persistance.features(self.config.environmentId, self.config.target).value
		do {
			let all: [Evaluation]? = try self.storageSource.getValue(forKey: allKey)
			guard var evaluations = all else {return}
			for (index, evaluation) in evaluations.enumerated() {
				if evaluation.flag == eval.flag {
					evaluations.remove(at: index)
					evaluations.insert(eval, at: index)
				}
			}
			try storageSource.saveValue(evaluations, key: allKey)
		} catch {
			print("no can do")
		}
	}
}
