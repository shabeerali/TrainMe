//
//  SwiftDataCourseStore.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataCourseStore: CourseStore {

    func loadCourses() throws -> [Course] {
        try fetchAllCourses().map(Self.course(from:))
    }

    func sync(remoteCourses: [Course]) throws -> [Course] {
        let existing = try fetchAllCourses()
        let remoteIds = Set(remoteCourses.map(\.id))
        var byId: [Int: CourseEntity] = [:]
        for entity in existing { byId[entity.id] = entity }

        // Courses removed on the server are removed locally (lessons cascade).
        for entity in existing where !remoteIds.contains(entity.id) {
            modelContext.delete(entity)
            byId[entity.id] = nil
        }

        for (index, remote) in remoteCourses.enumerated() {
            let entity: CourseEntity
            if let found = byId[remote.id] {
                entity = found
                entity.title = remote.title
                entity.instructor = remote.instructor
                entity.lessonCount = remote.lessons
                entity.sortOrder = index
            } else {
                entity = CourseEntity(id: remote.id, title: remote.title, instructor: remote.instructor,
                                      progress: remote.progress, lessonCount: remote.lessons, sortOrder: index)
                modelContext.insert(entity)
            }
            // Local completion state is the source of truth once lessons exist.
            entity.progress = entity.lessons.isEmpty ? remote.progress : Self.progress(of: entity)
        }

        try modelContext.save()
        return try fetchAllCourses().map(Self.course(from:))
    }

    func detail(for courseId: Int) throws -> CourseDetail? {
        guard let entity = try fetchCourse(id: courseId), !entity.lessons.isEmpty else { return nil }
        return Self.detail(from: entity)
    }

    func saveLessons(_ lessons: [Lesson], for courseId: Int) throws -> CourseDetail? {
        guard let entity = try fetchCourse(id: courseId) else { return nil }
        if entity.lessons.isEmpty {
            attach(lessons, to: entity)
            if !entity.lessons.isEmpty { entity.progress = Self.progress(of: entity) }
            try modelContext.save()
        }
        return Self.detail(from: entity)
    }

    func completeLesson(_ lessonId: Int, in courseId: Int) throws -> CourseDetail {
        guard let course = try fetchCourse(id: courseId) else { throw RepositoryError.courseNotFound }
        guard let lesson = course.lessons.first(where: { $0.id == lessonId }) else {
            throw RepositoryError.lessonNotFound
        }
        lesson.isCompleted = true
        course.progress = Self.progress(of: course)
        try modelContext.save()
        return Self.detail(from: course)
    }

    func clear() throws {
        for entity in try fetchAllCourses() { modelContext.delete(entity) }
        try modelContext.save()
    }

    // MARK: - Helpers

    private func fetchAllCourses() throws -> [CourseEntity] {
        try modelContext.fetch(FetchDescriptor<CourseEntity>(sortBy: [SortDescriptor(\.sortOrder)]))
    }

    private func fetchCourse(id: Int) throws -> CourseEntity? {
        var descriptor = FetchDescriptor<CourseEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func attach(_ lessons: [Lesson], to course: CourseEntity) {
        for (index, lesson) in lessons.enumerated() {
            let entity = LessonEntity(id: lesson.id, title: lesson.title,
                                      isCompleted: lesson.isCompleted, order: index)
            modelContext.insert(entity)
            entity.course = course
        }
    }

    private static func progress(of course: CourseEntity) -> Int {
        ProgressCalculator.percentage(completed: course.lessons.filter { $0.isCompleted }.count,
                                      total: course.lessons.count)
    }

    private static func course(from entity: CourseEntity) -> Course {
        Course(id: entity.id, title: entity.title, instructor: entity.instructor,
               progress: entity.progress, lessons: entity.lessonCount)
    }

    private static func detail(from entity: CourseEntity) -> CourseDetail {
        let lessons = entity.lessons
            .sorted { $0.order < $1.order }
            .map { Lesson(id: $0.id, title: $0.title, isCompleted: $0.isCompleted) }
        return CourseDetail(course: course(from: entity), lessons: lessons)
    }
}
