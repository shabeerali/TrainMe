import XCTest
import SwiftData
@testable import TrainMe

final class CourseRepositoryTests: XCTestCase {

    // MARK: - Test doubles

    private final class StubCourseAPI: CourseAPI {
        var isOffline = false
        // Server says course 1 is 50% done (2 of 4 lessons).
        var courses = [Course(id: 1, title: "Swift", instructor: "Ada", progress: 50, lessons: 4)]
        var lessons = (1...4).map { Lesson(id: $0, title: "Lesson \($0)", isCompleted: $0 <= 2) }

        func fetchCourses() async throws -> [Course] {
            if isOffline { throw APIError.noConnection }
            return courses
        }
        func fetchLessons(courseId: Int) async throws -> [Lesson] {
            if isOffline { throw APIError.noConnection }
            return lessons
        }
    }

    /// Real SwiftData store, kept in memory so tests are fast and isolated.
    private func makeStore() throws -> SwiftDataCourseStore {
        let container = try ModelContainer(
            for: CourseEntity.self, LessonEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataCourseStore(modelContainer: container)
    }

    // MARK: - Tests

    func testCompletingLessonUpdatesProgressAndSurvivesRefresh() async throws {
        let repo = DefaultCourseRepository(api: StubCourseAPI(), store: try makeStore())
        _ = try await repo.loadCourses()
        _ = try await repo.loadDetail(for: 1)          // opening the course stores its lessons

        let detail = try await repo.completeLesson(3, in: 1)

        XCTAssertTrue(detail.lessons.first { $0.id == 3 }?.isCompleted == true)
        XCTAssertEqual(detail.course.progress, 75)     // 3 of 4

        // The server still reports 50%; local completion must win after a refresh.
        let refreshed = try await repo.loadCourses()
        XCTAssertEqual(refreshed.courses.first?.progress, 75)
    }

    /// Once the dashboard has loaded, coming back to it offline shows the data, not an error.
    func testRevisitingDashboardOfflineShowsStoredData() async throws {
        let api = StubCourseAPI()
        let store = try makeStore()
        let repo = DefaultCourseRepository(api: api, store: store)
        let online = try await repo.loadCourses()

        api.isOffline = true
        let revisit = try await repo.loadCourses()
        XCTAssertEqual(revisit.source, .cache)
        XCTAssertEqual(revisit.courses, online.courses)

        // Same after an app restart (new repository instance, same on-disk store).
        let restarted = DefaultCourseRepository(api: api, store: store)
        let afterRestart = try await restarted.loadCourses()
        XCTAssertEqual(afterRestart.source, .cache)
        XCTAssertEqual(afterRestart.courses, online.courses)
    }

    /// The network error is reserved for the first visit, when there is nothing stored.
    func testFirstDashboardVisitWithoutInternetThrows() async throws {
        let api = StubCourseAPI()
        api.isOffline = true
        let repo = DefaultCourseRepository(api: api, store: try makeStore())

        do {
            _ = try await repo.loadCourses()
            XCTFail("Expected a network error")
        } catch {
            XCTAssertTrue(error.isConnectivityError)
        }
    }

    /// Same rule per screen: a course never opened errors offline; after one online visit it doesn't.
    func testCourseDetailsErrorsOnFirstOfflineVisitThenServesStoredLessons() async throws {
        let api = StubCourseAPI()
        let repo = DefaultCourseRepository(api: api, store: try makeStore())
        _ = try await repo.loadCourses()

        api.isOffline = true
        do {
            _ = try await repo.loadDetail(for: 1)
            XCTFail("Expected a network error on first visit")
        } catch {
            XCTAssertTrue(error.isConnectivityError)
        }

        api.isOffline = false
        _ = try await repo.loadDetail(for: 1)

        api.isOffline = true
        let revisit = try await repo.loadDetail(for: 1)
        XCTAssertEqual(revisit.lessons.count, 4)
    }
}
