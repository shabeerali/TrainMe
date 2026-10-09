import XCTest
@testable import TrainMe

private final class StubConnectivity: ConnectivityChecking, @unchecked Sendable {
    var isConnected = true
    func updates() -> AsyncStream<Bool> { AsyncStream { _ in } }
}

final class MockAuthServiceTests: XCTestCase {

    func testSuccessfulLoginIssuesTokenThatExpiresInThirtyMinutes() async throws {
        let issuedAt = Date(timeIntervalSince1970: 1_000_000)
        let service = MockAuthService(connectivity: StubConnectivity(), latency: .zero, now: { issuedAt })

        let token = try await service.login(email: MockAuthService.demoEmail,
                                            password: MockAuthService.demoPassword)

        XCTAssertFalse(token.value.isEmpty)
        XCTAssertEqual(token.expiresAt, issuedAt.addingTimeInterval(30 * 60))
    }

    func testLoginWithoutInternetFailsWithNetworkError() async {
        let connectivity = StubConnectivity()
        connectivity.isConnected = false
        let service = MockAuthService(connectivity: connectivity, latency: .zero)

        do {
            _ = try await service.login(email: MockAuthService.demoEmail,
                                        password: MockAuthService.demoPassword)
            XCTFail("Expected a network error")
        } catch {
            XCTAssertTrue(error.isConnectivityError)
        }
    }
}

@MainActor
final class SessionStoreTests: XCTestCase {

    private final class InMemoryTokenStorage: TokenStorage {
        var token: AuthToken?
        func load() -> AuthToken? { token }
        func save(_ token: AuthToken) throws { self.token = token }
        func clear() { token = nil }
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000_000)
    }

    private func token(expiringAt date: Date) -> AuthToken {
        AuthToken(value: "abc", email: Constants.MockData.loginDemoUserEmail, expiresAt: date)
    }

    func testValidStoredTokenSkipsLogin() {
        let clock = Clock()
        let storage = InMemoryTokenStorage()
        storage.token = token(expiringAt: clock.now.addingTimeInterval(10 * 60))

        let session = SessionStore(storage: storage, now: { clock.now })

        XCTAssertEqual(session.user?.email, Constants.MockData.loginDemoUserEmail)
    }

    func testExpiredStoredTokenRequiresLoginAndIsRemoved() {
        let clock = Clock()
        let storage = InMemoryTokenStorage()
        storage.token = token(expiringAt: clock.now.addingTimeInterval(-1))

        let session = SessionStore(storage: storage, now: { clock.now })

        XCTAssertNil(session.user)
        XCTAssertNil(storage.token)
    }

    func testSessionEndsWhenTokenExpiresWhileAppWasInBackground() {
        let clock = Clock()
        let storage = InMemoryTokenStorage()
        let session = SessionStore(storage: storage, now: { clock.now })
        session.signIn(token(expiringAt: clock.now.addingTimeInterval(30 * 60)))
        XCTAssertNotNil(session.user)

        clock.now = clock.now.addingTimeInterval(29 * 60)
        session.endSessionIfExpired()
        XCTAssertNotNil(session.user)                       // still valid at 29 min

        clock.now = clock.now.addingTimeInterval(2 * 60)    // 31 min total
        session.endSessionIfExpired()
        XCTAssertNil(session.user)
        XCTAssertNil(storage.token)
    }
}
