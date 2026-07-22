//
//  GoogleAuthFlow.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
enum GoogleAuthFlow {
    case signIn((Result<AuthDataResult, Error>) -> Void)
    case link((Result<AuthDataResult, Error>) -> Void)

    func complete(with result: Result<AuthDataResult, Error>) {
        switch self {
        case .signIn(let completion), .link(let completion):
            completion(result)
        }
    }
}

@MainActor
struct GoogleAuthState {
    let flow: GoogleAuthFlow
}

@MainActor
private enum GoogleAuthFlowCoordinator {
    static weak var activeService: FirebaseAuthService?
}

extension FirebaseAuthService {
    public func startSignInWithGoogle(
        presentingViewController: UIViewController,
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        startGoogleAuth(
            flow: .signIn(completion),
            presentingViewController: presentingViewController
        )
    }

    public func startSignInWithGoogle(
        presentingViewController: UIViewController
    ) async throws -> AuthDataResult {
        let transfer: MainActorTransfer<AuthDataResult> = try await withCheckedThrowingContinuation(
            isolation: MainActor.shared
        ) { continuation in
            startSignInWithGoogle(presentingViewController: presentingViewController) {
                resumeMainActorContinuation(continuation, with: $0)
            }
        }
        return transfer.value
    }

    public func startLinkWithGoogle(
        presentingViewController: UIViewController,
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        startGoogleAuth(
            flow: .link(completion),
            presentingViewController: presentingViewController
        )
    }

    public func startLinkWithGoogle(
        presentingViewController: UIViewController
    ) async throws -> AuthDataResult {
        let transfer: MainActorTransfer<AuthDataResult> = try await withCheckedThrowingContinuation(
            isolation: MainActor.shared
        ) { continuation in
            startLinkWithGoogle(presentingViewController: presentingViewController) {
                resumeMainActorContinuation(continuation, with: $0)
            }
        }
        return transfer.value
    }

    private func startGoogleAuth(
        flow: GoogleAuthFlow,
        presentingViewController: UIViewController
    ) {
        guard googleAuthState == nil, GoogleAuthFlowCoordinator.activeService == nil else {
            flow.complete(with: .failure(FirebaseAuthEasierError.authenticationFlowAlreadyInProgress))
            return
        }
        guard let clientID = auth.app?.options.clientID else {
            flow.complete(with: .failure(FirebaseAuthEasierError.missingGoogleClientID))
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        googleAuthState = GoogleAuthState(flow: flow)
        GoogleAuthFlowCoordinator.activeService = self
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            let transfer = MainActorTransfer(value: (result, error))
            Task { @MainActor in
                self?.handleGoogleSignInResult(
                    result: transfer.value.0,
                    error: transfer.value.1
                )
            }
        }
    }

    private func handleGoogleSignInResult(result: GIDSignInResult?, error: Error?) {
        guard let state = googleAuthState else {
            assertionFailure("Received a duplicate Google Sign-In callback.")
            return
        }
        googleAuthState = nil
        if GoogleAuthFlowCoordinator.activeService === self {
            GoogleAuthFlowCoordinator.activeService = nil
        }

        if let error {
            state.flow.complete(with: .failure(error))
            return
        }
        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else {
            state.flow.complete(with: .failure(FirebaseAuthEasierError.invalidGoogleCredential))
            return
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        switch state.flow {
        case .signIn:
            signInWithCredential(credential, completion: state.flow.complete(with:))
        case .link:
            linkCurrentUserWithCredential(credential, completion: state.flow.complete(with:))
        }
    }
}
