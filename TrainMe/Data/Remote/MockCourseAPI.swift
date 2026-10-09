//
//  MockCourseAPI.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

/// Stands in for a real backend. Like a real request it fails with `noConnection`
/// when the device has no internet.
struct MockCourseAPI: CourseAPI {
    let connectivity: ConnectivityChecking
    var latency: Duration = .milliseconds(700)

    func fetchCourses() async throws -> [Course] {
        try await awaitNetworkResponse()
        return try Self.decodeCourses()
    }

    func fetchLessons(courseId: Int) async throws -> [Lesson] {
        try await awaitNetworkResponse()
        guard let course = try Self.decodeCourses().first(where: { $0.id == courseId }) else {
            return []
        }
        // Seed completion from the course's server-side progress.
        //let completedCount = Int((Double(course.progress) / 100 * Double(course.lessons)).rounded())
        let names = Self.lessonTitles[courseId] ?? []
        return (0..<course.lessons).map { index in
            Lesson(id: index + 1,
                   title: index < names.count ? names[index] : "Lesson \(index + 1)",
                   isCompleted: false)
        }
    }

    // MARK: - Mock data

    private func awaitNetworkResponse() async throws {
        try await Task.sleep(for: latency)
        guard connectivity.isConnected else { throw APIError.noConnection }
    }

    private static func decodeCourses() throws -> [Course] {
        try JSONDecoder().decode([Course].self, from: Data(coursesJSON.utf8))
    }

    private static let coursesJSON = """
    [
      { "id": 1, "title": "Python Programming",     "instructor": "John Smith",     "progress": 0, "lessons": 10 },
      { "id": 2, "title": "Generative AI",          "instructor": "Sarah Williams", "progress": 0, "lessons": 6 },
      { "id": 3, "title": "Full Stack Development", "instructor": "David Brown",    "progress": 0, "lessons": 7 }
    ]
    """

    private static let lessonTitles: [Int: [String]] = [
        1: ["Introduction", "Variables & Data Types", "Functions", "OOP", "Control Flow",
            "Collections", "File Handling", "Error Handling", "Modules & Packages", "Testing"],
        2: ["What is Generative AI?", "Prompt Engineering Basics", "Large Language Models",
            "Embeddings & Vector Search", "Building a Chatbot", "Responsible AI"],
        3: ["Web Fundamentals", "HTML & CSS", "JavaScript Essentials", "React Basics",
            "REST APIs with Node", "Databases & SQL", "Authentication", "Deployment"]
    ]
}
