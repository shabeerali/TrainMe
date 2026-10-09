//
//  DashboardViewModel.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    enum State: Equatable {
        case loading
        case loaded([Course])
        case empty
        case failed(message: String, isNetworkError: Bool)
    }

    private(set) var state: State = .loading
    /// True when the list comes from offline storage because the network request failed.
    private(set) var isShowingCachedData = false

    private let repository: CourseRepository
    private let connectivity: ConnectivityChecking

    init(repository: CourseRepository, connectivity: ConnectivityChecking) {
        self.repository = repository
        self.connectivity = connectivity
    }

    func load() async {
        // Keep showing existing content during a refresh instead of flashing a spinner.
        if case .loaded = state {} else { state = .loading }

        do {
            let result = try await repository.loadCourses()
            isShowingCachedData = (result.source == .cache)
            state = result.courses.isEmpty ? .empty : .loaded(result.courses)
        } catch {
            if Task.isCancelled { return }
            isShowingCachedData = false
            state = .failed(message: error.localizedDescription,
                            isNetworkError: error.isConnectivityError)
        }
    }

    /// Reloads whenever connectivity flips: going offline keeps the stored data on screen
    /// (with the offline banner), coming back online refreshes it.
    func observeConnectivity() async {
        for await _ in connectivity.updates() {
            await load()
        }
    }
}
