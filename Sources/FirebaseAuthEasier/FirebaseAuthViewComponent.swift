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
    public let onSignInStart: ((SignInProviderType) -> Void)?
    public let handleSignIn: (SignInProviderType) -> Void
    public let content: () -> Content
    
    public init(
        providers: [SignInProviderType],
        isSigningIn: Bool,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        handleSignIn: @escaping (SignInProviderType) -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.providers = providers
        self.isSigningIn = isSigningIn
        self.onSignInStart = onSignInStart
        self.handleSignIn = handleSignIn
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            if #available(iOS 16.4, *) {
                ScrollView {
                    content()
                        .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ScrollView {
                    content()
                        .frame(maxWidth: .infinity)
                }
            }
            VStack {
                ForEach(providers, id: \.self) { provider in
                    SignInButton(
                        provider: provider,
                        action: { handleSignIn(provider) }
                    )
                    .disabled(isSigningIn)
                }
                .frame(height: 52)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    FirebaseAuthViewComponent(
        providers: [.apple, .google],
        isSigningIn: false,
        onSignInStart: { _ in },
        handleSignIn: { _ in },
        content: {
            Text("hoge")
        }
    )
}
