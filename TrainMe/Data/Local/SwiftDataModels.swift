//
//  SwiftDataModels.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import SwiftData

@Model
final class CourseEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var instructor: String
    var progress: Int
    var lessonCount: Int
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \LessonEntity.course)
    var lessons: [LessonEntity] = []

    init(id: Int, title: String, instructor: String, progress: Int, lessonCount: Int, sortOrder: Int) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.progress = progress
        self.lessonCount = lessonCount
        self.sortOrder = sortOrder
    }
}

@Model
final class LessonEntity {
    var id: Int
    var title: String
    var isCompleted: Bool
    var order: Int
    var course: CourseEntity?

    init(id: Int, title: String, isCompleted: Bool, order: Int) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
    }
}
