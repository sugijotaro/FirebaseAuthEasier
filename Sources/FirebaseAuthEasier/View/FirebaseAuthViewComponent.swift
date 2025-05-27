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
    
    public init(
        providers: [SignInProviderType],
        isSigningIn: Bool,
        labelType: SignInButtonLabelType = .signIn,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        handleSignIn: @escaping (SignInProviderType) -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.providers = providers
        self.isSigningIn = isSigningIn
        self.labelType = labelType
        self.onSignInStart = onSignInStart
        self.handleSignIn = handleSignIn
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
}

#Preview {
    FirebaseAuthViewComponent(
        providers: [.apple, .google],
        isSigningIn: false,
        labelType: .signIn,
        onSignInStart: { _ in },
        handleSignIn: { _ in },
        content: {
            FirebaseAuthDefaultContentView()
        }
    )
}
