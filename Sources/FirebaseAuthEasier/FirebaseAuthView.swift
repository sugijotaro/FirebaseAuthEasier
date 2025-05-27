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
    
    public init(
        providers: [SignInProviderType]? = nil,
        labelType: SignInButtonLabelType = .signIn,
        @ViewBuilder content: @escaping () -> Content = { FirebaseAuthDefaultContentView() },
        onSignInStart: ((SignInProviderType) -> Void)? = nil,
        didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: FirebaseAuthViewModel(
            providers: providers,
            labelType: labelType,
            onSignInStart: onSignInStart,
            didSignIn: didSignIn
        ))
        self.content = content
    }
    
    public var body: some View {
        FirebaseAuthViewComponent(
            providers: viewModel.providers,
            isSigningIn: viewModel.isSigningIn,
            labelType: viewModel.labelType,
            onSignInStart: viewModel.onSignInStart,
            handleSignIn: viewModel.handleSignIn,
            content: content
        )
    }
}
