//
//  AppleAuthFlow.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation
import OSLog

private let appleAuthLogger = Logger(
    subsystem: "FirebaseAuthEasier",
    category: "AppleAuthentication"
)

@MainActor
enum AppleAuthFlow {
    case signIn((Result<AuthDataResult, Error>) -> Void)
    case link((Result<AuthDataResult, Error>) -> Void)
    case credential((Result<AuthCredential, Error>) -> Void)

    func fail(with error: Error) {
        switch self {
        case .signIn(let completion), .link(let completion):
            completion(.failure(error))
        case .credential(let completion):
            completion(.failure(error))
        }
    }

    func completeAuthOperation(with result: Result<AuthDataResult, Error>) {
        switch self {
        case .signIn(let completion), .link(let completion):
            completion(result)
        case .credential(let completion):
            completion(.failure(FirebaseAuthEasierError.unexpectedAuthorizationCallback))
        }
    }

    func completeCredential(with credential: AuthCredential) {
        switch self {
        case .credential(let completion):
            completion(.success(credential))
        case .signIn(let completion), .link(let completion):
            completion(.failure(FirebaseAuthEasierError.unexpectedAuthorizationCallback))
        }
    }
}

@MainActor
struct AppleAuthState {
    let nonce: String
    let flow: AppleAuthFlow
    let controller: ASAuthorizationController
    let presentationAnchor: ASPresentationAnchor
}

extension FirebaseAuthService: ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    public func startSignInWithApple(
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        startAppleAuth(flow: .signIn(completion))
    }

    public func startSignInWithApple() async throws -> AuthDataResult {
        let transfer: MainActorTransfer<AuthDataResult> = try await withCheckedThrowingContinuation(
            isolation: MainActor.shared
        ) { continuation in
            startSignInWithApple { resumeMainActorContinuation(continuation, with: $0) }
        }
        return transfer.value
    }

    public func startLinkWithApple(
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        startAppleAuth(flow: .link(completion))
    }

    public func startLinkWithApple() async throws -> AuthDataResult {
        let transfer: MainActorTransfer<AuthDataResult> = try await withCheckedThrowingContinuation(
            isolation: MainActor.shared
        ) { continuation in
            startLinkWithApple { resumeMainActorContinuation(continuation, with: $0) }
        }
        return transfer.value
    }

    func credentialWithApple(
        completion: @MainActor @escaping (Result<AuthCredential, Error>) -> Void
    ) {
        startAppleAuth(flow: .credential(completion))
    }

    public func linkWithApple(
        nonce: String,
        idTokenString: String,
        fullName: PersonNameComponents?
    ) async throws -> AuthDataResult {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: fullName
        )
        return try await linkCurrentUserWithCredential(credential)
    }

    public func linkWithApple(
        nonce: String,
        idTokenString: String,
        fullName: PersonNameComponents?,
        completion: @MainActor @escaping (Result<AuthDataResult, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(.success(try await linkWithApple(
                    nonce: nonce,
                    idTokenString: idTokenString,
                    fullName: fullName
                )))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func startAppleAuth(flow: AppleAuthFlow) {
        guard appleAuthState == nil else {
            flow.fail(with: FirebaseAuthEasierError.authenticationFlowAlreadyInProgress)
            return
        }
        guard let presentationAnchor = resolveApplePresentationAnchor() else {
            flow.fail(with: FirebaseAuthEasierError.missingApplePresentationAnchor)
            return
        }

        let nonce: String
        do {
            nonce = try Self.randomNonceString()
        } catch {
            flow.fail(with: error)
            return
        }

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        appleAuthState = AppleAuthState(
            nonce: nonce,
            flow: flow,
            controller: controller,
            presentationAnchor: presentationAnchor
        )
        controller.performRequests()
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let state = takeAppleAuthState(for: controller) else {
            return
        }
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let token = appleCredential.identityToken,
              let tokenString = String(data: token, encoding: .utf8) else {
            state.flow.fail(with: FirebaseAuthEasierError.invalidAppleCredential)
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: state.nonce,
            fullName: appleCredential.fullName
        )
        switch state.flow {
        case .signIn:
            signInWithCredential(credential, completion: state.flow.completeAuthOperation(with:))
        case .link:
            linkCurrentUserWithCredential(
                credential,
                completion: state.flow.completeAuthOperation(with:)
            )
        case .credential:
            state.flow.completeCredential(with: credential)
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        guard let state = takeAppleAuthState(for: controller) else {
            return
        }
        state.flow.fail(with: error)
    }

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let state = appleAuthState, state.controller === controller {
            return state.presentationAnchor
        }
        appleAuthLogger.error("Requested a presentation anchor for an inactive flow.")
        return resolveApplePresentationAnchor() ?? ASPresentationAnchor()
    }

    private func takeAppleAuthState(for controller: ASAuthorizationController) -> AppleAuthState? {
        guard let state = appleAuthState else {
            appleAuthLogger.error("Ignored a duplicate Sign in with Apple delegate callback.")
            return nil
        }
        appleAuthState = nil
        guard state.controller === controller else {
            state.flow.fail(with: FirebaseAuthEasierError.unexpectedAuthorizationCallback)
            return nil
        }
        return state
    }

    private static func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else {
            throw FirebaseAuthEasierError.nonceGenerationFailed(status)
        }
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { characters[Int($0) % characters.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String($0, radix: 16).leftPadding(toLength: 2, withPad: "0") }
            .joined()
    }
}

private extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        guard count < toLength else { return self }
        return String(repeating: String(character), count: toLength - count) + self
    }
}
