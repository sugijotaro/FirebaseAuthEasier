import FirebaseAuth
@testable import FirebaseAuthEasier
import XCTest

final class AuthProviderIDTests: XCTestCase {
    func testKnownProviderIDsAreMapped() {
        XCTAssertEqual(AuthProviderID.from("apple.com"), .apple)
        XCTAssertEqual(AuthProviderID.from("google.com"), .google)
        XCTAssertEqual(AuthProviderID.from("password"), .email)
    }

    func testUnknownProviderIDIsPreservedAsCustomProvider() {
        XCTAssertEqual(AuthProviderID.from("oidc.example"), .custom("oidc.example"))
    }
}
