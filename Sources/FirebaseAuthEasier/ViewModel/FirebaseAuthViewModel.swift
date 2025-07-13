//
//  FirebaseAuthViewModel.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import Foundation
import FirebaseAuth
import Combine
import UIKit

@MainActor
public final class FirebaseAuthViewModel: ObservableObject {
    @Published public var isSigningIn: Bool = false
    @Published public private(set) var lastSignInResult: Result<AuthDataResult, Error>? = nil
    public let providers: [SignInProviderType]
    public let labelType: SignInButtonLabelType
    public let termsOfServiceURL: URL?
    public let privacyPolicyURL: URL?
    public let onSignInStart: ((SignInProviderType) -> Void)?
    public let didSignIn: ((Result<AuthDataResult, Error>) -> Void)?
    private let authService = FirebaseAuthService()
    
    public init(
        providers: [SignInProviderType]? = nil,
        labelType: SignInButtonLabelType = .signIn,
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil
    ) {
        self.providers = providers ?? [.apple, .google]
        self.labelType = labelType
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
        self.onSignInStart = onSignInStart
        self.didSignIn = didSignIn
    }
    
    public func handleSignIn(provider: SignInProviderType) {
        onSignInStart?(provider)
        isSigningIn = true
        switch provider {
        case .apple:
            authService.startSignInWithApple { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isSigningIn = false
                    self.lastSignInResult = result
                    self.didSignIn?(result)
                }
            }
        case .google:
            guard let rootVC = Self.getRootViewController() else {
                isSigningIn = false
                let error = NSError(domain: "FirebaseAuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "RootViewController not found."])
                let result: Result<AuthDataResult, Error> = .failure(error)
                self.lastSignInResult = result
                didSignIn?(result)
                return
            }
            authService.startSignInWithGoogle(presentingViewController: rootVC) { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isSigningIn = false
                    self.lastSignInResult = result
                    self.didSignIn?(result)
                }
            }
        case .anonymous:
            authService.signInAnonymously { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isSigningIn = false
                    self.lastSignInResult = result
                    self.didSignIn?(result)
                }
            }
        }
    }
    
    private static func getRootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        return windowScenes?.keyWindow?.rootViewController
    }
}
