//
//  CourseRepository.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

protocol CourseRepository {
    /// Network first. If the request fails and courses were loaded before, the stored copy is
    /// returned (`source == .cache`). The error only surfaces when there is nothing stored,
    /// i.e. the very first visit without internet.
    func loadCourses() async throws -> CourseLoadResult
    /// Local first: once a course's lessons were loaded they are served from storage (that is
    /// also where completion state lives). The network is only needed on the first visit.
    func loadDetail(for courseId: Int) async throws -> CourseDetail
    /// Marks a lesson completed, recomputes course progress, persists both.
    func completeLesson(_ lessonId: Int, in courseId: Int) async throws -> CourseDetail
    /// Clears all stored course data (used on logout).
    func resetCache() async
}

enum RepositoryError: LocalizedError {
    case courseNotFound
    case lessonNotFound

    var errorDescription: String? {
        switch self {
        case .courseNotFound: return "This course could not be found."
        case .lessonNotFound: return "This lesson could not be found."
        }
    }
}

actor DefaultCourseRepository: CourseRepository {
    private let api: CourseAPI
    private let store: CourseStore

    init(api: CourseAPI, store: CourseStore) {
        self.api = api
        self.store = store
    }

    func loadCourses() async throws -> CourseLoadResult {
        let remoteCourses: [Course]
        do {
            remoteCourses = try await api.fetchCourses()
        } catch {
            let stored = (try? await store.loadCourses()) ?? []
            guard !stored.isEmpty else { throw error }   // first visit, nothing to show
            return CourseLoadResult(courses: stored, source: .cache)
        }

        // One atomic store operation. Local lesson completion wins over server progress.
        // If persisting fails we still show what the server returned.
        let courses = (try? await store.sync(remoteCourses: remoteCourses)) ?? remoteCourses
        return CourseLoadResult(courses: courses, source: .remote)
    }

    func loadDetail(for courseId: Int) async throws -> CourseDetail {
        if let detail = try await store.detail(for: courseId) {
            return detail
        }
        let lessons = try await api.fetchLessons(courseId: courseId)
        guard let detail = try await store.saveLessons(lessons, for: courseId) else {
            throw RepositoryError.courseNotFound
        }
        return detail
    }

    func completeLesson(_ lessonId: Int, in courseId: Int) async throws -> CourseDetail {
        try await store.completeLesson(lessonId, in: courseId)
    }

    func resetCache() async {
        try? await store.clear()
    }
}
