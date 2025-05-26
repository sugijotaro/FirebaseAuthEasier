//
//  FirebaseAuthService.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

public final class FirebaseAuthService: NSObject {
    private let auth = Auth.auth()
    public override init() {
        super.init()
    }
    
    public func addAuthStateDidChangeListener(_ listener: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return auth.addStateDidChangeListener(listener)
    }
    
    public func removeAuthStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
    
    public func signInAnonymously(completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.signInAnonymously { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve anonymous auth result."])))
                return
            }
            completion(.success(authResult))
        }
    }
    
    public func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func reauthenticateIfNeeded(
        presentingViewController: UIViewController,
        for operation: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = auth.currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not found."])));
            return
        }
        operation { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                let authErr = AuthErrorCode(rawValue: error._code)
                if authErr == .requiresRecentLogin {
                    self?.startReauthenticationFlow(for: user, presentingViewController: presentingViewController) { reauthResult in
                        switch reauthResult {
                        case .success:
                            operation(completion)
                        case .failure(let reauthError):
                            completion(.failure(reauthError))
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func startReauthenticationFlow(
        for user: FirebaseAuth.User,
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let providerIDs = FirebaseAuthService.providerIDs(for: user)
        if providerIDs.contains(.google) {
            self.startSignInWithGoogle(presentingViewController: presentingViewController) { [weak self] result in
                switch result {
                case .success(let authResult):
                    self?.reauthenticate(with: authResult.credential, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else if providerIDs.contains(.apple) {
            self.startSignInWithApple { [weak self] result in
                switch result {
                case .success(let authResult):
                    self?.reauthenticate(with: authResult.credential, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No re-authenticatable provider found."])));
        }
    }
    
    private func reauthenticate(with credential: AuthCredential?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = auth.currentUser, let credential = credential else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve credential."])))
            return
        }
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    public func deleteAccount(
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        reauthenticateIfNeeded(
            presentingViewController: presentingViewController,
            for: { [weak self] opCompletion in
                guard let user = self?.auth.currentUser else {
                    opCompletion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not found."])));
                    return
                }
                user.delete { error in
                    if let error = error {
                        opCompletion(.failure(error))
                    } else {
                        opCompletion(.success(()))
                    }
                }
            },
            completion: completion
        )
    }
    
    public func signInWithCredential(_ credential: AuthCredential, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Firebase auth result."])))
            }
        }
    }
    
    public func linkCurrentUserWithCredential(_ credential: AuthCredential, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not found."])));
            return
        }
        currentUser.link(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to link account."])))
            }
        }
    }
    
    public static func providerIDs(for user: FirebaseAuth.User) -> [AuthProviderID] {
        return user.providerData.compactMap { AuthProviderID.from($0.providerID) }
    }
}
