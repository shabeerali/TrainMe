//
//  MockAuthService.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Security

struct MockAuthService: AuthService {
    static let demoEmail =  Constants.MockData.loginDemoUserEmail
    static let demoPassword = Constants.MockData.loginDemoUserPassword
    static let tokenLifetime: TimeInterval = 30 * 60

    let connectivity: ConnectivityChecking
    var latency: Duration = .seconds(1)
    var now: @Sendable () -> Date = { Date() }

    func login(email: String, password: String) async throws -> AuthToken {
        try await Task.sleep(for: latency)
        guard connectivity.isConnected else { throw APIError.noConnection }
        guard email.lowercased() == Self.demoEmail, password == Self.demoPassword else {
            throw AuthError.invalidCredentials
        }
        return AuthToken(value: Self.makeToken(),
                         email: email,
                         expiresAt: now().addingTimeInterval(Self.tokenLifetime))
    }

    private static func makeToken() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            return UUID().uuidString + UUID().uuidString
        }
        return Data(bytes).base64EncodedString()
    }
}
