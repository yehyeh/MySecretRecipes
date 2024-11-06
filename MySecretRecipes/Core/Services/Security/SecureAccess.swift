//
//  SecureAccess.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation
import Security
import LocalAuthentication
import CryptoKit

enum SecureAccessError: Error {
    case evaluatePolicy(NSError)
    case undefined
    case notAvailable
    case encryption(Error?)
    case decryption(Error?)
}

class SecureAccess {
    private let context = LAContext()

    func encryptRecipeDetails(_ details: Recipe.Details, for recipeId: String) async throws -> Data {
        guard let accessPolicy else {
            throw SecureAccessError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(accessPolicy,
                                   localizedReason: localizedReason) { success, authError in
                guard success else {
                    if let authError {
                        continuation.resume(throwing: SecureAccessError.evaluatePolicy(authError as NSError))
                    } else {
                        continuation.resume(throwing: SecureAccessError.undefined)
                    }
                    return
                }

                var encryptedData: Data?
                do {
                    let key = try self.generateKey(for: recipeId)
                    let jsonData = try JSONEncoder().encode(details)
                    let sealedBox = try AES.GCM.seal(jsonData, using: key)
                    encryptedData = sealedBox.combined
                    guard let encryptedData else {
                        continuation.resume(throwing: (SecureAccessError.encryption(nil)))
                        return
                    }

                    continuation.resume(returning: encryptedData)

                } catch {
                    print("Encryption error: \(error)")
                    continuation.resume(throwing: SecureAccessError.encryption(error))
                }
            }
        }
    }
    
    func decryptRecipeDetails(encryptedData: Data, for recipeId: String) async throws -> Recipe.Details {
        guard let accessPolicy else {
            throw SecureAccessError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(accessPolicy,
                                   localizedReason: localizedReason) { success, authError in
                guard success else {
                    if let authError {
                        continuation.resume(throwing: SecureAccessError.evaluatePolicy(authError as NSError))
                    } else {
                        continuation.resume(throwing: SecureAccessError.undefined)
                    }
                    return
                }

                do {
                    let key = try self.generateKey(for: recipeId)
                    let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
                    let decryptedData = try AES.GCM.open(sealedBox, using: key)
                    let details = try JSONDecoder().decode(Recipe.Details.self, from: decryptedData)

                    continuation.resume(returning: details)
                } catch {
                    print("decryption error: \(error)")
                    continuation.resume(throwing: SecureAccessError.encryption(error))
                }
            }
        }
    }
}

private extension SecureAccess {
    var accessPolicy: LAPolicy? {
        guard case .success(let policyType) = evaluateAccessPolicy else {
            return nil
        }
        return policyType
    }

    var evaluateAccessPolicy: Result<LAPolicy, SecureAccessError> {
        var error: NSError?
        var availableType: LAPolicy?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            availableType = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            availableType = .deviceOwnerAuthentication
        }

        if let policy = availableType {
            return .success(policy)
        } else if let error {
            return .failure(.evaluatePolicy(error))
        } else {
            return .failure(.notAvailable)
        }
    }

    func generateKey(for recipeId: String) throws -> SymmetricKey {
        let salt = "recipeId_\(recipeId)".data(using: .utf8)!
        let key = SymmetricKey(size: .bits256)
        return key
    }


    var localizedReason: String {
        "Please authenticate yourself to unlock recipes.".localizedCapitalized
    }

}
