import FirebaseAuth
@testable import FirebaseAuthEasier
import XCTest

@MainActor
final class FirebaseAuthSessionTests: XCTestCase {
    func testInitialStateIsUnresolvedUntilFirstListenerCallback() {
        let gateway = FakeSessionGateway()
        let session = FirebaseAuthSession(gateway: gateway)

        XCTAssertFalse(session.isAuthStateResolved)
        XCTAssertFalse(session.isSignedIn)

        gateway.sendAuthState(nil)

        XCTAssertTrue(session.isAuthStateResolved)
        XCTAssertFalse(session.isSignedIn)
        XCTAssertTrue(session.providerIDs.isEmpty)
    }

    func testSignOutTracksProgressAndReturnsToIdle() async throws {
        let gateway = FakeSessionGateway()
        let session = FirebaseAuthSession(gateway: gateway)

        try await session.signOut()

        XCTAssertEqual(gateway.signOutCallCount, 1)
        XCTAssertFalse(session.isSigningOut)
        if case .idle = session.signOutState {
            // Expected state.
        } else {
            XCTFail("Expected idle sign-out state")
        }
    }

    func testSignOutFailureIsPublishedAndCanBeCleared() async {
        let gateway = FakeSessionGateway()
        gateway.signOutError = TestError.expected
        let session = FirebaseAuthSession(gateway: gateway)

        do {
            try await session.signOut()
            XCTFail("Expected sign-out to fail")
        } catch TestError.expected {
            // Expected error.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        if case .failed = session.signOutState {
            // Expected state.
        } else {
            XCTFail("Expected failed sign-out state")
        }
        session.clearSignOutError()
        if case .idle = session.signOutState {
            // Expected state.
        } else {
            XCTFail("Expected idle state after clearing the error")
        }
    }
}

@MainActor
private final class FakeSessionGateway: FirebaseAuthSessionGateway {
    var currentUser: FirebaseAuth.User?
    var signOutError: Error?
    private(set) var signOutCallCount = 0
    private var listener: ((FirebaseAuth.User?) -> Void)?
    func addSessionStateDidChangeListener(
        _ listener: @escaping (FirebaseAuth.User?) -> Void
    ) -> FirebaseAuthStateListenerRegistration {
        self.listener = listener
        return FirebaseAuthStateListenerRegistration {}
    }

    func signOut() async throws {
        signOutCallCount += 1
        if let signOutError {
            throw signOutError
        }
        sendAuthState(nil)
    }

    func sendAuthState(_ user: FirebaseAuth.User?) {
        currentUser = user
        listener?(user)
    }
}

private enum TestError: Error {
    case expected
}
