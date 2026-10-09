//
//  LoginViewModel.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum State: Equatable {
        case idle
        case loading
        case failed(String)
    }

    var email = ""
    var password = ""
    private(set) var state: State = .idle
    private(set) var hasSubmitted = false

    private let authService: AuthService
    private let onLoginSuccess: @MainActor (AuthToken) -> Void

    init(authService: AuthService, onLoginSuccess: @escaping @MainActor (AuthToken) -> Void) {
        self.authService = authService
        self.onLoginSuccess = onLoginSuccess
    }

    // Errors only appear after the first submit attempt, then update live.
    var emailError: String? { hasSubmitted ? Self.emailError(for: email) : nil }
    var passwordError: String? { hasSubmitted ? Self.passwordError(for: password) : nil }
    var isLoading: Bool { state == .loading }

    func login() async {
        hasSubmitted = true
        guard !isLoading, emailError == nil, passwordError == nil else { return }

        state = .loading
        do {
            let token = try await authService.login(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            state = .idle
            onLoginSuccess(token)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }


    static func emailError(for email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Email is required." }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid email address." : nil
    }

    static func passwordError(for password: String) -> String? {
        if password.isEmpty { return "Password is required." }
        return password.count < 6 ? "Password must be at least 6 characters." : nil
    }
}
