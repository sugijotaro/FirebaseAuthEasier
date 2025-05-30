//
//  FirebaseAuthViewComponent.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import SwiftUI
import FirebaseAuth

public struct FirebaseAuthViewComponent<Content: View>: View {
    @ObservedObject public var viewModel: FirebaseAuthViewModel
    public let content: () -> Content
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public init(
        viewModel: FirebaseAuthViewModel,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 16.0, *) {
                ViewThatFits(in: .vertical) {
                    content()
                    ScrollView {
                        content()
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ScrollView {
                    content()
                        .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 16) {
                if viewModel.isSigningIn {
                    ProgressView(signingInText)
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let signInResult = viewModel.lastSignInResult {
                    switch signInResult {
                    case .success:
                        Label(resultStatusText(true), systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.headline)
                    case .failure:
                        Label(resultStatusText(false), systemImage: "xmark.octagon.fill")
                            .foregroundColor(.red)
                            .font(.headline)
                        signInButtonsView
                    }
                } else {
                    signInButtonsView
                }
                if viewModel.termsOfServiceURL != nil || viewModel.privacyPolicyURL != nil {
                    let legalText = legalNoticeMarkdown(terms: viewModel.termsOfServiceURL, privacy: viewModel.privacyPolicyURL)
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
            ForEach(viewModel.providers, id: \.self) { provider in
                let (buttonStyle, hasBorder) = buttonStyleAndBorder(for: provider, colorScheme: colorScheme)
                SignInButton(
                    provider: provider,
                    buttonStyle: buttonStyle,
                    labelType: viewModel.labelType,
                    hasBorder: hasBorder,
                    action: { viewModel.handleSignIn(provider: provider) }
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
    
    private var signingInText: String {
        switch viewModel.labelType {
        case .signIn:
            return NSLocalizedString("Signing in...", bundle: Bundle.module, comment: "")
        case .signUp:
            return NSLocalizedString("Signing up...", bundle: Bundle.module, comment: "")
        case .continue:
            return NSLocalizedString("Processing...", bundle: Bundle.module, comment: "")
        }
    }
    
    private var resultStatusText: (Bool) -> String {
        { isSuccess in
            if isSuccess {
                return NSLocalizedString("Success", bundle: Bundle.module, comment: "")
            } else {
                return NSLocalizedString("Failed", bundle: Bundle.module, comment: "")
            }
        }
    }
    
    private func legalNoticeMarkdown(terms: URL?, privacy: URL?) -> String? {
        switch (terms, privacy) {
        case let (terms?, privacy?):
            return String(
                format: NSLocalizedString("By continuing, you are indicating that you accept our [Terms of Service](%@) and [Privacy Policy](%@).", bundle: Bundle.module, comment: "Legal notice with both Terms of Service and Privacy Policy"),
                terms.absoluteString, privacy.absoluteString
            )
        case let (terms?, nil):
            return String(
                format: NSLocalizedString("By continuing, you are indicating that you accept our [Terms of Service](%@).", bundle: Bundle.module, comment: "Legal notice with only Terms of Service"),
                terms.absoluteString
            )
        case let (nil, privacy?):
            return String(
                format: NSLocalizedString("By continuing, you are indicating that you accept our [Privacy Policy](%@).", bundle: Bundle.module, comment: "Legal notice with only Privacy Policy"),
                privacy.absoluteString
            )
        default:
            return nil
        }
    }
}

#Preview {
    let viewModel = FirebaseAuthViewModel(
        providers: [.apple, .google],
        labelType: .signIn,
        termsOfServiceURL: URL(string: "https://example.com/terms"),
        privacyPolicyURL: URL(string: "https://example.com/privacy")
    )
    return FirebaseAuthViewComponent(
        viewModel: viewModel,
        content: {
            FirebaseAuthDefaultContentView()
        }
    )
}
