//
//  FirebaseAuthViewModel.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import Combine
import FirebaseAuth
import Foundation
import UIKit

public typealias AuthenticationPresentingViewControllerProvider = @MainActor () -> UIViewController?

@MainActor
public final class FirebaseAuthViewModel: ObservableObject {
    @Published public private(set) var isSigningIn = false
    @Published public private(set) var lastSignInResult: Result<AuthDataResult, Error>?

    public let providers: [SignInProviderType]
    public let labelType: SignInButtonLabelType
    public let termsOfServiceURL: URL?
    public let privacyPolicyURL: URL?
    public let onSignInStart: ((SignInProviderType) -> Void)?
    public let didSignIn: ((Result<AuthDataResult, Error>) -> Void)?

    private let authService: FirebaseAuthService
    private let presentingViewControllerProvider: AuthenticationPresentingViewControllerProvider

    public init(
        providers: [SignInProviderType]? = nil,
        labelType: SignInButtonLabelType = .signIn,
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        authService: FirebaseAuthService? = nil,
        presentingViewControllerProvider: AuthenticationPresentingViewControllerProvider? = nil,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil
    ) {
        self.providers = providers ?? [.apple, .google]
        self.labelType = labelType
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
        self.authService = authService ?? FirebaseAuthService()
        self.presentingViewControllerProvider = presentingViewControllerProvider
            ?? Self.defaultPresentingViewController
        self.onSignInStart = onSignInStart
        self.didSignIn = didSignIn
    }

    public func handleSignIn(provider: SignInProviderType) {
        guard !isSigningIn else { return }
        onSignInStart?(provider)
        isSigningIn = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            let result: Result<AuthDataResult, Error>
            do {
                result = .success(try await self.signIn(with: provider))
            } catch {
                result = .failure(error)
            }
            self.isSigningIn = false
            self.lastSignInResult = result
            self.didSignIn?(result)
        }
    }

    private func signIn(with provider: SignInProviderType) async throws -> AuthDataResult {
        switch provider {
        case .apple:
            return try await authService.startSignInWithApple()
        case .google:
            guard let presentingViewController = presentingViewControllerProvider() else {
                throw FirebaseAuthEasierError.missingAuthenticationPresentationContext
            }
            return try await authService.startSignInWithGoogle(
                presentingViewController: presentingViewController
            )
        case .anonymous:
            return try await authService.signInAnonymously()
        }
    }

    private static func defaultPresentingViewController() -> UIViewController? {
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        for scene in activeScenes {
            let window = scene.windows.first(where: \.isKeyWindow)
                ?? scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 })
            if let rootViewController = window?.rootViewController {
                return topViewController(from: rootViewController)
            }
        }
        return nil
    }

    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigationController = root as? UINavigationController,
           let visible = navigationController.visibleViewController {
            return topViewController(from: visible)
        }
        if let tabBarController = root as? UITabBarController,
           let selected = tabBarController.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }
}
