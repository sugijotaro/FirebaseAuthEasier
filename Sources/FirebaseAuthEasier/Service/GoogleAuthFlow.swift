//
//  GoogleAuthFlow.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

extension FirebaseAuthService {
    private enum GoogleAuthFlow {
        case signIn((Result<AuthDataResult, Error>) -> Void)
        case link((Result<AuthDataResult, Error>) -> Void)
    }
    
    private struct GoogleAuthState {
        var flow: GoogleAuthFlow
    }
    
    nonisolated(unsafe) private static var googleAuthState: GoogleAuthState?
    
    // MARK: - Public API
    public func startSignInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Self.startGoogleAuth(flow: .signIn(completion), authServiceInstance: self, presentingViewController: presentingViewController)
    }
    
    public func startLinkWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Self.startGoogleAuth(flow: .link(completion), authServiceInstance: self, presentingViewController: presentingViewController)
    }
    
    // MARK: - Private Shared Logic
    private static func startGoogleAuth(flow: GoogleAuthFlow, authServiceInstance: FirebaseAuthService, presentingViewController: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            switch flow {
            case .signIn(let completion), .link(let completion):
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing Google Client ID."])));
            }
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        googleAuthState = GoogleAuthState(flow: flow)
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            handleGoogleSignInResult(result: result, error: error, authServiceInstance: authServiceInstance)
        }
    }
    
    private static func handleGoogleSignInResult(result: GIDSignInResult?, error: Error?, authServiceInstance: FirebaseAuthService) {
        guard let state = googleAuthState else { return }
        if let error = error {
            switch state.flow {
            case .signIn(let completion), .link(let completion):
                completion(.failure(error))
            }
            googleAuthState = nil
            return
        }
        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else {
            switch state.flow {
            case .signIn(let completion), .link(let completion):
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Google user credentials."])));
            }
            googleAuthState = nil
            return
        }
        switch state.flow {
        case .signIn(let completion):
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            authServiceInstance.signInWithCredential(credential, completion: completion)
            googleAuthState = nil
        case .link(let completion):
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            authServiceInstance.linkCurrentUserWithCredential(credential, completion: completion)
            googleAuthState = nil
        }
    }
}
