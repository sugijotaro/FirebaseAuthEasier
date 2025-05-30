//
//  FirebaseAuthView.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import SwiftUI
import FirebaseAuth

public struct FirebaseAuthView<Content: View>: View {
    @StateObject private var viewModel: FirebaseAuthViewModel
    private let content: () -> Content
    @State private var signInResult: Result<AuthDataResult, Error>? = nil
    
    public init(
        providers: [SignInProviderType]? = nil,
        labelType: SignInButtonLabelType = .signIn,
        termsOfServiceURL: URL? = nil,
        privacyPolicyURL: URL? = nil,
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { FirebaseAuthDefaultContentView() }
    ) {
        _viewModel = StateObject(wrappedValue: FirebaseAuthViewModel(
            providers: providers,
            labelType: labelType,
            termsOfServiceURL: termsOfServiceURL,
            privacyPolicyURL: privacyPolicyURL,
            onSignInStart: onSignInStart,
            didSignIn: { result in
                didSignIn?(result)
            }
        ))
        self.content = content
    }
    
    public var body: some View {
        FirebaseAuthViewComponent(
            viewModel: viewModel,
            content: content
        )
        .onChange(of: viewModel.isSigningIn) { isSigningIn in
            if !isSigningIn {
                signInResult = viewModel.lastSignInResult
            }
        }
    }
}
