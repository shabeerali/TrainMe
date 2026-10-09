//
//  KeychainTokenStorage.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Security

enum KeychainError: Error {
    case unhandled(OSStatus)
}

/// Keeps the auth token (value + expiry) in the iOS Keychain as a single generic-password item.
struct KeychainTokenStorage: TokenStorage {
    private let service = Constants.KeyChain.service
    private let account = Constants.KeyChain.account 

    func load() -> AuthToken? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthToken.self, from: data)
    }

    func save(_ token: AuthToken) throws {
        let data = try JSONEncoder().encode(token)

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary,
                                         [kSecValueData as String: data] as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var item = baseQuery
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unhandled(addStatus) }
        default:
            throw KeychainError.unhandled(updateStatus)
        }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }
}
