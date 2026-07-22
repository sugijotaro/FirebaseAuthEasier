//
//  FirebaseAuthService.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import Foundation
import AuthenticationServices
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

public typealias ApplePresentationAnchorProvider = @MainActor () -> ASPresentationAnchor?

/// The single gateway for Firebase Authentication operations provided by this package.
@MainActor
public final class FirebaseAuthService: NSObject {
    let auth: Auth
    var appleAuthState: AppleAuthState?
    var googleAuthState: GoogleAuthState?
    private var applePresentationAnchorProvider: ApplePresentationAnchorProvider?

    public var currentUser: FirebaseAuth.User? { auth.currentUser }

    /// Creates a service backed by an explicitly supplied Firebase Auth instance.
    /// Use this initializer for named Firebase apps, tests, and deterministic initialization.
    public init(
        auth: Auth,
        applePresentationAnchorProvider: ApplePresentationAnchorProvider? = nil
    ) {
        self.auth = auth
        self.applePresentationAnchorProvider = applePresentationAnchorProvider
        super.init()
    }

    /// Creates a service using the default Firebase app.
    /// Firebase must already be configured with `FirebaseApp.configure()`.
    public override convenience init() {
        guard FirebaseApp.app() != nil else {
            preconditionFailure(FirebaseAuthEasierError.firebaseNotConfigured.localizedDescription)
        }
        self.init(auth: Auth.auth())
    }

    /// Returns a default service without trapping when Firebase has not yet been configured.
    public static func configured() throws -> FirebaseAuthService {
        guard FirebaseApp.app() != nil else {
            throw FirebaseAuthEasierError.firebaseNotConfigured
        }
        return FirebaseAuthService(auth: Auth.auth())
    }

    /// Changes how Sign in with Apple chooses the window for presentation.
    /// Set this when the service belongs to a particular SwiftUI scene or iPad window.
    public func setApplePresentationAnchorProvider(
        _ provider: ApplePresentationAnchorProvider?
    ) {
        applePresentationAnchorProvider = provider
    }

    func resolveApplePresentationAnchor() -> ASPresentationAnchor? {
        if let anchor = applePresentationAnchorProvider?() {
            return anchor
        }

        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        for scene in activeScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
            if let visibleWindow = scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 }) {
                return visibleWindow
            }
        }
        return nil
    }

    @discardableResult
    public func addAuthStateDidChangeListener(
        _ listener: @escaping (Auth, FirebaseAuth.User?) -> Void
    ) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener(listener)
    }

    public func removeAuthStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }

    public func signInAnonymously() async throws -> AuthDataResult {
        try await auth.signInAnonymously()
    }

    public func signInAnonymously(
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(.success(try await signInAnonymously()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func signOut() async throws {
        try auth.signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    public func signOut(
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                try await signOut()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func signInWithCredential(_ credential: AuthCredential) async throws -> AuthDataResult {
        try await auth.signIn(with: credential)
    }

    public func signInWithCredential(
        _ credential: AuthCredential,
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(.success(try await signInWithCredential(credential)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func linkCurrentUserWithCredential(_ credential: AuthCredential) async throws -> AuthDataResult {
        guard let currentUser = auth.currentUser else {
            throw FirebaseAuthEasierError.currentUserNotFound
        }
        return try await currentUser.link(with: credential)
    }

    public func linkCurrentUserWithCredential(
        _ credential: AuthCredential,
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(.success(try await linkCurrentUserWithCredential(credential)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func reauthenticateIfNeeded(
        presentingViewController: UIViewController,
        for operation: @MainActor @escaping (@MainActor @escaping (Result<Void, Error>) -> Void) -> Void,
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = auth.currentUser else {
            completion(.failure(FirebaseAuthEasierError.currentUserNotFound))
            return
        }

        operation { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                guard AuthErrorCode(rawValue: error._code) == .requiresRecentLogin else {
                    completion(.failure(error))
                    return
                }
                guard let self else {
                    completion(.failure(error))
                    return
                }
                self.startReauthenticationFlow(
                    for: user,
                    presentingViewController: presentingViewController
                ) { reauthenticationResult in
                    switch reauthenticationResult {
                    case .success:
                        operation(completion)
                    case .failure(let reauthenticationError):
                        completion(.failure(reauthenticationError))
                    }
                }
            }
        }
    }

    public func deleteAccount(presentingViewController: UIViewController) async throws {
        try await withCheckedThrowingContinuation(isolation: MainActor.shared) { continuation in
            deleteAccount(presentingViewController: presentingViewController) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func deleteAccount(
        presentingViewController: UIViewController,
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        reauthenticateIfNeeded(
            presentingViewController: presentingViewController,
            for: { [weak self] operationCompletion in
                guard let user = self?.auth.currentUser else {
                    operationCompletion(.failure(FirebaseAuthEasierError.currentUserNotFound))
                    return
                }
                user.delete { error in
                    if let error {
                        operationCompletion(.failure(error))
                    } else {
                        operationCompletion(.success(()))
                    }
                }
            },
            completion: completion
        )
    }

    public static func providerIDs(for user: FirebaseAuth.User) -> [AuthProviderID] {
        user.providerData.compactMap { AuthProviderID.from($0.providerID) }
    }

    private func startReauthenticationFlow(
        for user: FirebaseAuth.User,
        presentingViewController: UIViewController,
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        let providerIDs = Self.providerIDs(for: user)
        if providerIDs.contains(.google) {
            credentialWithGoogle(presentingViewController: presentingViewController) { [weak self] result in
                self?.finishReauthentication(for: user, from: result, completion: completion)
            }
        } else if providerIDs.contains(.apple) {
            credentialWithApple { [weak self] result in
                self?.finishReauthentication(for: user, from: result, completion: completion)
            }
        } else {
            completion(.failure(FirebaseAuthEasierError.noReauthenticationProvider))
        }
    }

    private func finishReauthentication(
        for user: FirebaseAuth.User,
        from result: Result<AuthCredential, Error>,
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        switch result {
        case .success(let credential):
            reauthenticate(user: user, with: credential, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func reauthenticate(
        user: FirebaseAuth.User,
        with credential: AuthCredential,
        completion: @MainActor @escaping (Result<Void, Error>) -> Void
    ) {
        user.reauthenticate(with: credential) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

extension FirebaseAuthService: FirebaseAuthSessionGateway {
    func addSessionStateDidChangeListener(
        _ listener: @escaping (FirebaseAuth.User?) -> Void
    ) -> FirebaseAuthStateListenerRegistration {
        let auth = auth
        let handle = auth.addStateDidChangeListener { _, user in listener(user) }
        return FirebaseAuthStateListenerRegistration {
            auth.removeStateDidChangeListener(handle)
        }
    }
}
