//
//  CourseAPI.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

protocol CourseAPI {
    func fetchCourses() async throws -> [Course]
    func fetchLessons(courseId: Int) async throws -> [Lesson]
}

enum APIError: LocalizedError {
    case noConnection

    var errorDescription: String? {
        switch self {
        case .noConnection: return Constants.Error.noConnectivity
        }
    }
}

extension Error {
    /// True for "no internet" failures, from the mock API or a real URLSession.
    var isConnectivityError: Bool {
        if let apiError = self as? APIError, apiError == .noConnection { return true }
        if let urlError = self as? URLError {
            return [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed].contains(urlError.code)
        }
        return false
    }
}
