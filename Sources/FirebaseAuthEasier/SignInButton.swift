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

public struct SignInButton: View {
    public let provider: SignInProviderType
    public let action: () -> Void
    
    public init(provider: SignInProviderType, action: @escaping () -> Void) {
        self.provider = provider
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
                            Text("Sign in with Apple")
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
                            Text("Sign in with Google")
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
}

#Preview {
    VStack {
        SignInButton(provider: .apple, action: { print("apple") })
            .frame(height: 44)
        SignInButton(provider: .google, action: { print("google") })
            .frame(height: 44)
        Spacer()
    }
    .padding(.horizontal)
}
