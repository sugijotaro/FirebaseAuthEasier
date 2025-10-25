//
//  AppleAuthFlow.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

extension FirebaseAuthService: ASAuthorizationControllerDelegate {
    private enum AppleAuthFlow {
        case signIn((Result<AuthDataResult, Error>) -> Void)
        case link((Result<AuthDataResult, Error>) -> Void)
    }
    
    private struct AppleAuthState {
        var nonce: String
        var flow: AppleAuthFlow
    }
    
    nonisolated(unsafe) private static var appleAuthState: AppleAuthState?
    
    // MARK: - Public API
    public func startSignInWithApple(completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Self.startAppleAuth(flow: .signIn(completion), delegate: self)
    }
    
    public func startLinkWithApple(completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Self.startAppleAuth(flow: .link(completion), delegate: self)
    }
    
    public func linkWithApple(nonce: String, idTokenString: String, fullName: PersonNameComponents?, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                        rawNonce: nonce,
                                                        fullName: fullName)
        linkCurrentUserWithCredential(credential, completion: completion)
    }
    
    // MARK: - Private Shared Logic
    private static func startAppleAuth(flow: AppleAuthFlow, delegate: ASAuthorizationControllerDelegate) {
        let nonce = randomNonceString()
        appleAuthState = AppleAuthState(nonce: nonce, flow: flow)
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let state = Self.appleAuthState else {
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            switch state.flow {
            case .signIn(let completion), .link(let completion):
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch/serialize identity token"])))
            }
            Self.appleAuthState = nil
            return
        }
        switch state.flow {
        case .signIn(let completion):
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                            rawNonce: state.nonce,
                                                            fullName: appleIDCredential.fullName)
            signInWithCredential(credential, completion: completion)
            Self.appleAuthState = nil
        case .link(let completion):
            linkWithApple(nonce: state.nonce, idTokenString: idTokenString, fullName: appleIDCredential.fullName, completion: completion)
            Self.appleAuthState = nil
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let state = Self.appleAuthState {
            switch state.flow {
            case .signIn(let completion), .link(let completion):
                completion(.failure(error))
            }
            Self.appleAuthState = nil
        }
    }
    
    // MARK: - Utility
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
