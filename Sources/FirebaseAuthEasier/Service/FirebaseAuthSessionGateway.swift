//
//  FirebaseAuthSessionGateway.swift
//  FirebaseAuthEasier
//

import FirebaseAuth

@MainActor
protocol FirebaseAuthSessionGateway: AnyObject {
    var currentUser: FirebaseAuth.User? { get }

    func addSessionStateDidChangeListener(
        _ listener: @escaping (FirebaseAuth.User?) -> Void
    ) -> FirebaseAuthStateListenerRegistration
    func signOut() async throws
}

/// Firebase Auth documents listener registration and removal as thread-safe. Keeping the
/// non-Sendable SDK handle inside this narrow wrapper lets its deinitializer cancel safely.
final class FirebaseAuthStateListenerRegistration: @unchecked Sendable {
    private let cancellation: () -> Void

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    deinit {
        cancellation()
    }
}
