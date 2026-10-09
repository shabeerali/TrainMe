//
//  Models.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

struct User: Equatable, Sendable {
    let email: String
}

struct Course: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let instructor: String
    var progress: Int          // 0...100
    let lessons: Int           // total lesson count
}

struct Lesson: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    var isCompleted: Bool
}

struct CourseDetail: Equatable, Sendable {
    let course: Course
    let lessons: [Lesson]
}

enum DataSource: Sendable {
    case remote
    case cache
}

struct CourseLoadResult: Sendable {
    let courses: [Course]
    let source: DataSource
}

/// Issued on successful login. `expiresAt` is checked on launch and whenever the app returns to the foreground.
struct AuthToken: Codable, Equatable, Sendable {
    let value: String
    let email: String
    let expiresAt: Date

    func isExpired(at date: Date) -> Bool { date >= expiresAt }
}
