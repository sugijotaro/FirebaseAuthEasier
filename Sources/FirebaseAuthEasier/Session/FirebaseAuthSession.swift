//
//  FirebaseAuthSession.swift
//  FirebaseAuthEasier
//

import Combine
import FirebaseAuth

/// Observable authentication state for use as the single source of truth in client apps.
@MainActor
public final class FirebaseAuthSession: ObservableObject {
    public enum SignOutState {
        case idle
        case signingOut
        case failed(Error)
    }

    @Published public private(set) var currentUser: FirebaseAuth.User?
    @Published public private(set) var isAuthStateResolved = false
    @Published public private(set) var providerIDs: [AuthProviderID] = []
    @Published public private(set) var signOutState: SignOutState = .idle

    public var isSignedIn: Bool { currentUser != nil }
    public var isAnonymous: Bool { currentUser?.isAnonymous == true }
    public var isSigningOut: Bool {
        if case .signingOut = signOutState {
            true
        } else {
            false
        }
    }

    private let gateway: any FirebaseAuthSessionGateway
    private var authStateListenerRegistration: FirebaseAuthStateListenerRegistration?

    public convenience init(service: FirebaseAuthService) {
        self.init(gateway: service)
    }

    /// Creates a session using the default Firebase app.
    ///
    /// Firebase must already be configured. For deterministic setup or named Firebase apps,
    /// create a `FirebaseAuthService` with an injected `Auth` instance and use `init(service:)`.
    public convenience init() {
        self.init(service: FirebaseAuthService())
    }

    init(gateway: any FirebaseAuthSessionGateway) {
        self.gateway = gateway
        currentUser = gateway.currentUser
        providerIDs = gateway.currentUser.map(FirebaseAuthService.providerIDs(for:)) ?? []
        authStateListenerRegistration = gateway.addSessionStateDidChangeListener { [weak self] user in
            guard let self else { return }
            self.currentUser = user
            self.providerIDs = user.map(FirebaseAuthService.providerIDs(for:)) ?? []
            self.isAuthStateResolved = true
            if user == nil, self.isSigningOut {
                self.signOutState = .idle
            }
        }
    }

    public func usesProvider(_ providerID: AuthProviderID) -> Bool {
        providerIDs.contains(providerID)
    }

    public func signOut() async throws {
        guard !isSigningOut else { return }
        signOutState = .signingOut

        do {
            try await gateway.signOut()
            // Firebase normally delivers the nil-user listener callback immediately after sign-out.
            // Reset here as well so state cannot remain stuck if a custom Auth implementation delays it.
            signOutState = .idle
        } catch {
            signOutState = .failed(error)
            throw error
        }
    }

    public func clearSignOutError() {
        if case .failed = signOutState {
            signOutState = .idle
        }
    }
}
