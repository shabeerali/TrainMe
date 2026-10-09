//
//  CourseDetailView.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import SwiftUI

struct CourseDetailView: View {
    @State private var viewModel: CourseDetailViewModel

    init(viewModel: CourseDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView(Constants.Presentation.loadingLessonMsg)
            case .failed(let message, let isNetworkError):
                ContentUnavailableView {
                    Label(isNetworkError ? Constants.Presentation.noInternet: Constants.Presentation.lessonLoadFailed,
                          systemImage: isNetworkError ? "wifi.slash" : "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button(Constants.Presentation.tryAgain) { Task { await viewModel.load() } }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                lessonList
            }
        }
        .navigationTitle(viewModel.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .alert(Constants.Presentation.lessonUpdateFailed,
               isPresented: Binding(get: { viewModel.actionError != nil },
                                    set: { if !$0 { viewModel.actionError = nil } }),
               actions: { Button(Constants.Presentation.okay, role: .cancel) {} },
               message: { Text(viewModel.actionError ?? "") })
    }

    private var lessonList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.course.title).font(.title2.bold())
                    Text("with \(viewModel.course.instructor)").foregroundStyle(.secondary)
                    ProgressView(value: Double(viewModel.course.progress), total: 100)
                    Text("\(viewModel.course.progress)% complete · \(viewModel.completedCount) of \(viewModel.lessons.count) lessons")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(Constants.Presentation.lessons) {
                ForEach(viewModel.lessons) { lesson in
                    LessonRow(lesson: lesson) {
                        Task { await viewModel.markCompleted(lesson) }
                    }
                }
            }
        }
        .animation(.default, value: viewModel.lessons)
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                if lesson.isCompleted {
                    Label(Constants.Presentation.completed, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label(Constants.Presentation.pending, systemImage: "circle")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            Spacer()

            if !lesson.isCompleted {
                Button(Constants.Presentation.markComplete, action: onComplete)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
