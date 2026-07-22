# FirebaseAuthEasier

[日本語 README](./README.ja.md)

[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

FirebaseAuthEasier adds Apple, Google, and anonymous Firebase Authentication flows to SwiftUI apps. It includes customizable sign-in UI, an observable authentication session, and callback plus async/await service APIs.

## Features

- `FirebaseAuthSession` tracks the current user, initial auth resolution, linked provider IDs, and sign-out progress/errors.
- `FirebaseAuthService` is the single gateway for authentication operations.
- Async/await APIs cover anonymous, Apple, Google, credential, link, sign-out, and account-deletion operations.
- Existing callback APIs remain available.
- Apple flow state is instance-owned and main-actor isolated; overlapping flows are rejected with an error.
- Apple presentation anchors and Google presenting view controllers can be injected for multi-window SwiftUI and iPad apps.
- `Auth` can be injected for named Firebase apps, tests, and deterministic initialization.
- iOS 15 remains supported. Newer SwiftUI APIs are used behind availability checks where appropriate.

## Requirements

- iOS 15.0+
- Swift 6.0+
- firebase-ios-sdk 11.13.0 up to, but not including, 13.0.0
- GoogleSignIn-iOS 8.0.0 up to, but not including, 10.0.0

## Installation

Add the package with Swift Package Manager:

```swift
.package(url: "https://github.com/sugijotaro/FirebaseAuthEasier.git", from: "1.0.0")
```

## Firebase setup

1. Add `GoogleService-Info.plist` by following the [Firebase Apple platform setup guide](https://firebase.google.com/docs/ios/setup).
2. Call `FirebaseApp.configure()` before creating `FirebaseAuthService`, `FirebaseAuthSession`, or `FirebaseAuthView`.
3. Enable the Apple, Google, and/or Anonymous providers in Firebase Console.
4. Add the Sign in with Apple capability when using Apple authentication.
5. Configure the Google OAuth client when using Google authentication.

The zero-argument `FirebaseAuthService()` initializer requires an already configured default Firebase app and stops with a clear precondition message otherwise. For recoverable setup validation, use `try FirebaseAuthService.configured()`. For named apps or dependency injection, use `FirebaseAuthService(auth:)`.

```swift
import FirebaseAuth
import FirebaseAuthEasier

let service = FirebaseAuthService(auth: Auth.auth())
let session = FirebaseAuthSession(service: service)
```

## Observable authentication session

Use one service and one session as your app's authentication source of truth. `isAuthStateResolved` prevents signed-out UI from flashing before Firebase delivers its initial listener callback.

```swift
import FirebaseAuth
import FirebaseAuthEasier
import SwiftUI

struct AuthGate: View {
    @StateObject private var session: FirebaseAuthSession
    private let authService: FirebaseAuthService

    init(auth: Auth = Auth.auth()) {
        let service = FirebaseAuthService(auth: auth)
        authService = service
        _session = StateObject(wrappedValue: FirebaseAuthSession(service: service))
    }

    var body: some View {
        Group {
            if !session.isAuthStateResolved {
                ProgressView("Loading…")
            } else if session.isSignedIn {
                VStack {
                    Text("Signed in")
                    Text(session.providerIDs.map(\.rawValue).joined(separator: ", "))
                    Button("Sign out") {
                        Task {
                            do {
                                try await session.signOut()
                            } catch {
                                // Present the error from session.signOutState.
                            }
                        }
                    }
                    .disabled(session.isSigningOut)
                }
            } else {
                FirebaseAuthView(authService: authService)
            }
        }
    }
}
```

Useful session state:

- `currentUser`, `isSignedIn`, and `isAnonymous`
- `isAuthStateResolved`
- `providerIDs` and `usesProvider(_:)`
- `signOutState` and `isSigningOut`

The session unregisters its Firebase listener when released. State mutations are main-actor isolated for SwiftUI and strict-concurrency safety.

## FirebaseAuthView

The simplest sign-in screen remains:

```swift
FirebaseAuthView()
```

The existing customization API remains source compatible, with optional service and presentation-context injection added:

```swift
FirebaseAuthView(
    providers: [.apple, .google, .anonymous],
    labelType: .continue,
    termsOfServiceURL: URL(string: "https://example.com/terms"),
    privacyPolicyURL: URL(string: "https://example.com/privacy"),
    authService: authService,
    presentingViewControllerProvider: { mySceneRootViewController },
    onSignInStart: { provider in
        print("Starting \(provider)")
    },
    didSignIn: { result in
        print(result)
    }
) {
    VStack {
        Image(systemName: "person.circle")
        Text("Welcome")
    }
}
```

Defaults are Apple and Google providers, the `.signIn` label, no legal links, and `FirebaseAuthDefaultContentView`.

## Async/await service APIs

`FirebaseAuthService` is `@MainActor` because Apple/Google authentication and presentation are UI-bound.

```swift
let service = FirebaseAuthService()

let anonymousResult = try await service.signInAnonymously()
let appleResult = try await service.startSignInWithApple()
let googleResult = try await service.startSignInWithGoogle(
    presentingViewController: viewController
)
let credentialResult = try await service.signInWithCredential(credential)
let linkedResult = try await service.linkCurrentUserWithCredential(credential)
try await service.signOut()
try await service.deleteAccount(presentingViewController: viewController)
```

Apple and Google linking also have async APIs:

```swift
let appleLink = try await service.startLinkWithApple()
let googleLink = try await service.startLinkWithGoogle(
    presentingViewController: viewController
)
```

The callback forms, such as `signOut(completion:)`, `signInAnonymously(completion:)`, and the provider flow completion handlers, remain available for existing clients.

## Multi-window Apple presentation

By default, the service searches foreground-active scenes and uses the key or visible window. For deterministic multi-window behavior, inject the window owned by the relevant scene:

```swift
let service = FirebaseAuthService(
    auth: Auth.auth(),
    applePresentationAnchorProvider: { sceneWindow }
)
```

You can replace it later with `setApplePresentationAnchorProvider(_:)`. If no anchor is available, Apple authentication completes with `FirebaseAuthEasierError.missingApplePresentationAnchor` instead of silently failing. Starting a second Apple flow on the same service completes with `authenticationFlowAlreadyInProgress`.

## Using SignInButton independently

```swift
SignInButton(
    provider: .apple,
    buttonStyle: .black,
    labelStyle: .titleAndIcon,
    labelType: .signIn,
    cornerStyle: .radius(12),
    hasBorder: true,
    action: startAppleSignIn
)
```

## Migration notes

- Existing callback APIs and the original `FirebaseAuthView` arguments are retained.
- Prefer a shared `FirebaseAuthSession` over reimplementing an auth-state listener in each app.
- Prefer async/await APIs in new code.
- `FirebaseAuthService`, `FirebaseAuthSession`, and `FirebaseAuthViewModel` are main-actor isolated. Code that previously called the service from a background context must switch to the main actor, for example with `Task { @MainActor in ... }`.
- Configure Firebase before using zero-argument initializers, or inject an `Auth` instance.
- Apple and Google overlapping interactive flows are now explicitly rejected rather than overwriting shared completion state.
- `FirebaseAuthView` no longer keeps a duplicate unused sign-in result; `FirebaseAuthViewModel.lastSignInResult` remains the displayed result and `didSignIn` remains the public completion hook.

## Notes

- Provider configuration, URL schemes, entitlements, and valid Firebase project credentials are still required.
- Apple authorization UI should be verified on a signed-in device as well as a simulator; automated tests cannot complete the system account-consent flow.
- `swift test` on the macOS host is not the supported path for this iOS-only package. Run the package scheme with an iOS Simulator destination in Xcode or `xcodebuild`.

## License

MIT © Jotaro Sugiyama
