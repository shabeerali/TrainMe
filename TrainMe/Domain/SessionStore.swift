//
//  SessionStore.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Observation


protocol TokenStorage {
    func load() -> AuthToken?
    func save(_ token: AuthToken) throws
    func clear()
}

/// Source of truth for "is the user signed in?". A stored, unexpired token means signed in,
/// so the app opens straight to the dashboard; an expired token sends the user back to login.
@MainActor
@Observable
final class SessionStore {
    private(set) var user: User?

    private let storage: TokenStorage
    private let now: () -> Date

    init(storage: TokenStorage, now: @escaping () -> Date = { Date() }) {
        self.storage = storage
        self.now = now

        if let token = storage.load() {
            if token.isExpired(at: now()) {
                storage.clear()
            } else {
                user = User(email: token.email)
            }
        }
    }

    func signIn(_ token: AuthToken) {
        try? storage.save(token)
        user = User(email: token.email)
    }

    func signOut() {
        storage.clear()
        user = nil
    }

    /// Call when the app comes to the foreground: ends the session if the token has expired
    /// (or was removed from the Keychain).
    func endSessionIfExpired() {
        guard user != nil else { return }
        guard let token = storage.load(), !token.isExpired(at: now()) else {
            signOut()
            return
        }
    }
}
