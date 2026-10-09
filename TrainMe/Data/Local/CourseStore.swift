//
//  CourseStore.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation

/// Local persistence boundary. Every method is a single atomic operation so the
/// repository never has to juggle partial writes.
protocol CourseStore {
    func loadCourses() async throws -> [Course]
    /// Upserts courses (in server order), removes courses the server no longer returns, and
    /// keeps progress derived from locally stored lessons where they exist.
    /// Returns the resulting courses.
    func sync(remoteCourses: [Course]) async throws -> [Course]
    /// nil when this course's lessons were never stored.
    func detail(for courseId: Int) async throws -> CourseDetail?
    func saveLessons(_ lessons: [Lesson], for courseId: Int) async throws -> CourseDetail?
    func completeLesson(_ lessonId: Int, in courseId: Int) async throws -> CourseDetail
    func clear() async throws
}
