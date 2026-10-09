
//
//  AppContainer.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let session: SessionStore

    private let connectivity: ConnectivityChecking
    private let authService: AuthService
    private let repository: CourseRepository

    init() {
        let connectivity = NetworkMonitor()
        let tokenStorage = KeychainTokenStorage()
        Self.discardKeychainLeftoversOnFreshInstall(tokenStorage)

        self.connectivity = connectivity
        self.session = SessionStore(storage: tokenStorage)
        self.authService = MockAuthService(connectivity: connectivity)
        self.repository = DefaultCourseRepository(
            api: MockCourseAPI(connectivity: connectivity),
            store: SwiftDataCourseStore(modelContainer: Self.makeModelContainer())
        )
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService) { [session] token in
            session.signIn(token)
        }
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(repository: repository, connectivity: connectivity)
    }

    func makeCourseDetailViewModel(for course: Course) -> CourseDetailViewModel {
        CourseDetailViewModel(course: course, repository: repository)
    }

   
    func logout() async {
        await repository.resetCache()
        session.signOut()
    }

    // MARK: - Setup helpers

    private static func discardKeychainLeftoversOnFreshInstall(_ storage: TokenStorage) {
        let key = "trainme.hasLaunchedBefore"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        storage.clear()
        UserDefaults.standard.set(true, forKey: key)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([CourseEntity.self, LessonEntity.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Disk store unusable (e.g. failed migration): run in memory rather than crash.
            let memory = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memory)
        }
    }
}
