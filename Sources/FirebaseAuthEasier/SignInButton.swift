//
//  SignInButton.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/27.
//

import SwiftUI

public enum SignInProviderType {
    case apple
    case google
}

public enum SignInButtonLabelType {
    case signIn
    case signUp
    case `continue`
}

public struct SignInButton: View {
    public let provider: SignInProviderType
    public let labelType: SignInButtonLabelType?
    public let action: () -> Void
    
    public init(provider: SignInProviderType, labelType: SignInButtonLabelType? = .signIn, action: @escaping () -> Void) {
        self.provider = provider
        self.labelType = labelType
        self.action = action
    }
    
    public var body: some View {
        Group {
            switch provider {
            case .apple:
                HStack {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Image("ic_apple", bundle: Bundle.module)
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 20, height: 20)
                            Text(buttonLabelText)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 180,
                       maxWidth: .infinity,
                       minHeight: 40,
                       maxHeight: .infinity
                )
                .background(.black)
                .cornerRadius(6)
            case .google:
                HStack {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Image("ic_google", bundle: Bundle.module)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(buttonLabelText)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 180,
                       maxWidth: .infinity,
                       minHeight: 40,
                       maxHeight: .infinity
                )
                .background(.white)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black, lineWidth: 0.5)
                )
            }
        }
    }
    
    private var buttonLabelText: String {
        let type = labelType ?? .signIn
        switch provider {
        case .apple:
            switch type {
            case .signIn:
                return "Sign in with Apple"
            case .signUp:
                return "Sign up with Apple"
            case .continue:
                return "Continue with Apple"
            }
        case .google:
            switch type {
            case .signIn:
                return "Sign in with Google"
            case .signUp:
                return "Sign up with Google"
            case .continue:
                return "Continue with Google"
            }
        }
    }
}

#Preview {
    VStack {
        SignInButton(provider: .apple, labelType: .continue, action: { print("apple") })
            .frame(height: 44)
        SignInButton(provider: .google, action: { print("google") })
            .frame(height: 44)
        Spacer()
    }
    .padding(.horizontal)
}
