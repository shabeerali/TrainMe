//
//  AuthService.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

protocol AuthService {
    func login(email: String, password: String) async throws -> AuthToken
}

enum AuthError: LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Incorrect email or password. Please try again."
        }
    }
}
