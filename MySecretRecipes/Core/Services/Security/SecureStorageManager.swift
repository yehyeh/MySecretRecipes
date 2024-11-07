//
//  SecureStorageManager.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation
import LocalAuthentication
import CryptoKit

enum SecurityError: Error {
    case cancelled
    case encoding
    case encryption
    case decryption
    case biometricsNotAvailable
    case keyStorage
    case keyRetrieval
}

protocol SecureStorageManagerProtocol {
    associatedtype Item: Codable
    func encrypt(_ item: Item, with itemId: String) throws -> Data
    func decrypt(itemId: String) async throws -> Item
}

class SecureStorageManager<T: Codable>: SecureStorageManagerProtocol {
    static func manager<U: Codable>() -> SecureStorageManager<U> {
        return SecureStorageManager<U>()
    }

    private let keychainService = "com.mysecret.recipes"
    private let keyPrefix = "\(T.self)_id_"

    func encrypt(_ item: T, with itemId: String) throws -> Data {
        let key = try generateAndStoreKey(for: itemId)

        let encoder = JSONEncoder()
        let itemData = try encoder.encode(item)

        let sealedBox = try AES.GCM.seal(itemData, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryption
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).\(itemId)",
            kSecAttrAccount as String: itemId,
            kSecValueData as String: encrypted
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(
                [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "\(keychainService).\(itemId)",
                    kSecAttrAccount as String: itemId
                ] as CFDictionary,
                [kSecValueData as String: encrypted] as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw SecurityError.encryption
            }
        } else if status != errSecSuccess {
            throw SecurityError.encryption
        }

        return encrypted
    }

    func decrypt(itemId: String) async throws -> T {
        let context = getContext()
        var error: NSError?

        guard context.canEvaluatePolicy(authPolicy, error: &error) else {
            throw SecurityError.biometricsNotAvailable
        }

        do {
            guard try await context.evaluatePolicy(authPolicy, localizedReason: Constant.UI.reasonForAuthentication) else {
                throw SecurityError.cancelled
            }
        } catch let error {
            print(error.localizedDescription)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).\(itemId)",
            kSecAttrAccount as String: itemId,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let encryptedData = result as? Data else {
            throw SecurityError.decryption
        }

        let key = try retrieveKey(for: itemId)

        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: decryptedData)
    }
}

private extension SecureStorageManager {

    func getContext() -> LAContext {
        let context = LAContext()
        context.localizedReason = Constant.UI.reasonForAuthentication
        return context
    }

    var authPolicy: LAPolicy {
        .deviceOwnerAuthenticationWithBiometrics
    }

    func generateAndStoreKey(for itemId: String) throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).\(keyPrefix)\(itemId)",
            kSecAttrAccount as String: "\(keyPrefix)\(itemId)",
            kSecValueData as String: keyData
        ]

        let status = SecItemAdd(keyQuery as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw SecurityError.keyStorage
        }

        return key
    }

    func retrieveKey(for itemId: String) throws -> SymmetricKey {
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).\(keyPrefix)\(itemId)",
            kSecAttrAccount as String: "\(keyPrefix)\(itemId)",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(keyQuery as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw SecurityError.keyRetrieval
        }

        return SymmetricKey(data: keyData)
    }
}
