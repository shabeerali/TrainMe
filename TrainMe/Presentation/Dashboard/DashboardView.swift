//
//  DashboardView.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var path: [Course] = []

    private let makeDetailViewModel: (Course) -> CourseDetailViewModel
    private let onLogout: () -> Void

    init(viewModel: DashboardViewModel,
         makeDetailViewModel: @escaping (Course) -> CourseDetailViewModel,
         onLogout: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.makeDetailViewModel = makeDetailViewModel
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(Constants.Presentation.myCourses)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Constants.Presentation.logout, action: onLogout)
                    }
                }
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(viewModel: makeDetailViewModel(course))
                }
                // Runs each time the dashboard appears, so progress is fresh after returning from details.
                .task { await viewModel.load() }
                .task { await viewModel.observeConnectivity() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(Constants.Presentation.loadingCoursesMsg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                Constants.Presentation.noCourses,
                systemImage: "book.closed",
                description: Text(Constants.Presentation.coursesEnrollMsg)
            )

        case .failed(let message, let isNetworkError):
            ContentUnavailableView {
                Label(isNetworkError ? Constants.Presentation.noInternet : Constants.Presentation.courseLoadFailed,
                      systemImage: isNetworkError ? "wifi.slash" : "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button(Constants.Presentation.tryAgain) { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }

        case .loaded(let courses):
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isShowingCachedData {
                        Label(Constants.Presentation.courseOfflineMsg, systemImage: "icloud.slash")
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                    ForEach(courses) { course in
                        CourseCardView(course: course) { path.append(course) }
                    }
                }
                .padding()
            }
            .refreshable { await viewModel.load() }
        }
    }
}

struct CourseCardView: View {
    let course: Course
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title).font(.headline)
                Label(course.instructor, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(course.progress), total: 100)

            HStack {
                Text("\(course.progress)% \(Constants.Presentation.complete)")
                Spacer()
                Label("\(course.lessons) \(Constants.Presentation.lessons)", systemImage: "list.bullet")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(action: onContinue) {
                Text(Constants.Presentation.continueMsg).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onContinue)
        .accessibilityElement(children: .contain)
    }
}
