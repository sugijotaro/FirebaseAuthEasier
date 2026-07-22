import AuthenticationServices
import FirebaseAuth
import FirebaseCore
@testable import FirebaseAuthEasier
import UIKit
import XCTest

@MainActor
final class AppleAuthFlowTests: XCTestCase {
    func testOverlappingFlowIsRejectedWithoutReplacingActiveFlow() {
        let service = makeService()
        let activeController = makeController()
        let activeState = AppleAuthState(
            nonce: "active-nonce",
            flow: .signIn { _ in },
            controller: activeController,
            presentationAnchor: UIWindow()
        )
        service.appleAuthState = activeState

        var receivedError: Error?
        service.startSignInWithApple { result in
            if case .failure(let error) = result {
                receivedError = error
            }
        }

        XCTAssertTrue(service.appleAuthState?.controller === activeController)
        XCTAssertEqual(
            receivedError as? FirebaseAuthEasierError,
            .authenticationFlowAlreadyInProgress
        )
        service.appleAuthState = nil
    }

    func testMatchingFailureDelegateCompletesAndClearsFlowExactlyOnce() {
        let service = makeService()
        let controller = makeController()
        var completionCount = 0
        var receivedError: Error?
        service.appleAuthState = AppleAuthState(
            nonce: "nonce",
            flow: .signIn { result in
                completionCount += 1
                if case .failure(let error) = result {
                    receivedError = error
                }
            },
            controller: controller,
            presentationAnchor: UIWindow()
        )

        service.authorizationController(controller: controller, didCompleteWithError: TestFlowError.expected)
        service.authorizationController(controller: controller, didCompleteWithError: TestFlowError.expected)

        XCTAssertEqual(completionCount, 1)
        XCTAssertNil(service.appleAuthState)
        XCTAssertEqual(receivedError as? TestFlowError, .expected)
    }

    func testMismatchedDelegateFailsActiveFlowAndClearsIt() {
        let service = makeService()
        let activeController = makeController()
        var receivedError: Error?
        service.appleAuthState = AppleAuthState(
            nonce: "nonce",
            flow: .link { result in
                if case .failure(let error) = result {
                    receivedError = error
                }
            },
            controller: activeController,
            presentationAnchor: UIWindow()
        )

        service.authorizationController(
            controller: makeController(),
            didCompleteWithError: TestFlowError.expected
        )

        XCTAssertEqual(
            receivedError as? FirebaseAuthEasierError,
            .unexpectedAuthorizationCallback
        )
        XCTAssertNil(service.appleAuthState)
    }

    private func makeService() -> FirebaseAuthService {
        let appName = "FirebaseAuthEasierTests"
        let app: FirebaseApp
        if let configuredApp = FirebaseApp.app(name: appName) {
            app = configuredApp
        } else {
            let options = FirebaseOptions(
                googleAppID: "1:1234567890:ios:abcdef123456",
                gcmSenderID: "1234567890"
            )
            options.apiKey = "test-api-key"
            options.projectID = "firebase-auth-easier-tests"
            FirebaseApp.configure(name: appName, options: options)
            guard let configuredApp = FirebaseApp.app(name: appName) else {
                fatalError("Unable to configure the Firebase test app.")
            }
            app = configuredApp
        }
        return FirebaseAuthService(
            auth: Auth.auth(app: app),
            applePresentationAnchorProvider: { UIWindow() }
        )
    }

    private func makeController() -> ASAuthorizationController {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        return ASAuthorizationController(authorizationRequests: [request])
    }
}

private enum TestFlowError: Error {
    case expected
}
