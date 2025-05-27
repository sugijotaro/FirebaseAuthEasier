//
//  FirebaseAuthViewComponent.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import SwiftUI
import FirebaseAuth

public struct FirebaseAuthViewComponent<Content: View>: View {
    public let providers: [SignInProviderType]
    public let isSigningIn: Bool
    public let labelType: SignInButtonLabelType
    public let onSignInStart: ((SignInProviderType) -> Void)?
    public let handleSignIn: (SignInProviderType) -> Void
    public let content: () -> Content
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    public let termsOfServiceURL: URL?
    public let privacyPolicyURL: URL?
    public let signInResult: Result<AuthDataResult, Error>?
    
    public init(
        providers: [SignInProviderType],
        isSigningIn: Bool,
        labelType: SignInButtonLabelType = .signIn,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        handleSignIn: @escaping (SignInProviderType) -> Void,
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        signInResult: Result<AuthDataResult, Error>? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.providers = providers
        self.isSigningIn = isSigningIn
        self.labelType = labelType
        self.onSignInStart = onSignInStart
        self.handleSignIn = handleSignIn
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
        self.signInResult = signInResult
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 16.0, *) {
                ViewThatFits {
                    content()
                    ScrollView {
                        content()
                    }
                }
            } else {
                ScrollView {
                    content()
                }
            }
            VStack(spacing: 16) {
                if isSigningIn {
                    ProgressView("Signing in...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let signInResult = signInResult {
                    switch signInResult {
                    case .success:
                        Label("Sign in successful", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.headline)
                    case .failure:
                        Label("Sign in failed", systemImage: "xmark.octagon.fill")
                            .foregroundColor(.red)
                            .font(.headline)
                        signInButtonsView
                    }
                } else {
                    signInButtonsView
                }
                if termsOfServiceURL != nil || privacyPolicyURL != nil {
                    let legalText = legalNoticeMarkdown(terms: termsOfServiceURL, privacy: privacyPolicyURL)
                    if let legalText = legalText {
                        Text(.init(legalText))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    private var signInButtonsView: some View {
        VStack(spacing: 8) {
            ForEach(providers, id: \ .self) { provider in
                let (buttonStyle, hasBorder) = buttonStyleAndBorder(for: provider, colorScheme: colorScheme)
                SignInButton(
                    provider: provider,
                    buttonStyle: buttonStyle,
                    labelType: labelType,
                    hasBorder: hasBorder,
                    action: { handleSignIn(provider) }
                )
                .frame(height: 52)
            }
        }
    }
    
    private func buttonStyleAndBorder(for provider: SignInProviderType, colorScheme: ColorScheme) -> (SignInButtonStyle, Bool) {
        switch provider {
        case .apple:
            return colorScheme == .dark ? (.white, false) : (.black, false)
        case .google:
            return colorScheme == .dark ? (.black, true) : (.white, true)
        }
    }
    
    private func legalNoticeMarkdown(terms: URL?, privacy: URL?) -> String? {
        switch (terms, privacy) {
        case let (terms?, privacy?):
            return "By continuing, you are indicating that you accept our [Terms of Service](\(terms.absoluteString)) and [Privacy Policy](\(privacy.absoluteString))."
        case let (terms?, nil):
            return "By continuing, you are indicating that you accept our [Terms of Service](\(terms.absoluteString))."
        case let (nil, privacy?):
            return "By continuing, you are indicating that you accept our [Privacy Policy](\(privacy.absoluteString))."
        default:
            return nil
        }
    }
}

#Preview("Default") {
    FirebaseAuthViewComponent(
        providers: [.apple, .google],
        isSigningIn: false,
        labelType: .signIn,
        onSignInStart: { _ in },
        handleSignIn: { _ in },
        termsOfServiceURL: URL(string: "apple.com"),
        privacyPolicyURL: URL(string: "apple.com"),
        signInResult: nil,
        content: {
            FirebaseAuthDefaultContentView()
        }
    )
}

#Preview("Failure") {
    FirebaseAuthViewComponent(
        providers: [.apple, .google],
        isSigningIn: false,
        labelType: .signIn,
        onSignInStart: { _ in },
        handleSignIn: { _ in },
        termsOfServiceURL: URL(string: "apple.com"),
        privacyPolicyURL: URL(string: "apple.com"),
        signInResult: .failure(NSError(domain: "", code: -1)),
        content: {
            FirebaseAuthDefaultContentView()
        }
    )
}
