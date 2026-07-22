# Changelog

## 2.0.0 — 2026-07-22

### Added

- `FirebaseAuthSession`, an observable main-actor store for the current user, initial auth resolution, provider IDs, and sign-out state.
- Async/await APIs for anonymous, Apple, Google, credential, linking, sign-out, and account-deletion operations.
- `FirebaseAuth.Auth` injection through `FirebaseAuthService(auth:)` and recoverable default-app validation through `FirebaseAuthService.configured()`.
- Injectable Apple presentation anchors and Google presenting view controllers for multi-window SwiftUI and iPad apps.
- Unit tests for session state, provider mapping, and Apple flow completion/overlap behavior.

### Changed

- `FirebaseAuthService`, `FirebaseAuthSession`, and `FirebaseAuthViewModel` are main-actor isolated for strict-concurrency safety.
- Apple and Google interactive flow state is concurrency-safe, and overlapping flows now fail explicitly.
- `FirebaseAuthView` uses a single result source and supports service/presentation-context injection.
- The sample app and English/Japanese documentation now use the observable session and async/await APIs.

### Fixed

- Every active Apple authorization delegate path now completes once with success or failure instead of silently returning.
- Apple authorization presentation now uses the relevant foreground window and supports explicit scene injection.
- Interactive reauthentication no longer performs a normal Firebase sign-in first, preventing accidental current-user and account-deletion target changes.
- Sign-out progress and errors can no longer leave client UI in an indeterminate state.

### Migration

- Existing callback APIs remain available, but calls must respect `@MainActor` isolation.
- Configure Firebase before using zero-argument initializers, or inject an `Auth` instance.
- Replace app-specific auth-state listeners with a shared `FirebaseAuthSession` where possible.
- Overlapping Apple or Google flows that previously overwrote completion state now return `FirebaseAuthEasierError.authenticationFlowAlreadyInProgress`.

The minimum deployment target remains iOS 15.
