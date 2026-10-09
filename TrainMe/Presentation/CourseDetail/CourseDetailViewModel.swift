//
//  CourseDetailViewModel.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CourseDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed(message: String, isNetworkError: Bool)
    }

    private(set) var course: Course
    private(set) var lessons: [Lesson] = []
    private(set) var state: State = .loading
    var actionError: String?

    private let repository: CourseRepository

    init(course: Course, repository: CourseRepository) {
        self.course = course
        self.repository = repository
    }

    var completedCount: Int { lessons.filter(\.isCompleted).count }

    func load() async {
        if lessons.isEmpty { state = .loading }
        do {
            apply(try await repository.loadDetail(for: course.id))
        } catch {
            if Task.isCancelled { return }
            state = .failed(message: error.localizedDescription,
                            isNetworkError: error.isConnectivityError)
        }
    }

    func markCompleted(_ lesson: Lesson) async {
        guard !lesson.isCompleted else { return }
        do {
            apply(try await repository.completeLesson(lesson.id, in: course.id))
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func apply(_ detail: CourseDetail) {
        course = detail.course
        lessons = detail.lessons
        state = .loaded
    }
}
