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
    
    public init(
        providers: [SignInProviderType],
        isSigningIn: Bool,
        labelType: SignInButtonLabelType = .signIn,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        handleSignIn: @escaping (SignInProviderType) -> Void,
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.providers = providers
        self.isSigningIn = isSigningIn
        self.labelType = labelType
        self.onSignInStart = onSignInStart
        self.handleSignIn = handleSignIn
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 4) {
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
            VStack {
                ForEach(providers, id: \.self) { provider in
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
            .padding()
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

#Preview {
    FirebaseAuthViewComponent(
        providers: [.apple, .google],
        isSigningIn: false,
        labelType: .signIn,
        onSignInStart: { _ in },
        handleSignIn: { _ in },
        termsOfServiceURL: URL(string: "apple.com"),
        privacyPolicyURL: URL(string: "apple.com"),
        content: {
            FirebaseAuthDefaultContentView()
        }
    )
}
