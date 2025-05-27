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

public enum SignInButtonCornerStyle {
    case radius(Int)
    case capsule
}

public enum SignInButtonLabelStyle {
    case iconOnly
    case titleAndIcon
}

public struct SignInButton: View {
    public let provider: SignInProviderType
    public let labelType: SignInButtonLabelType?
    public let cornerStyle: SignInButtonCornerStyle
    public let labelStyle: SignInButtonLabelStyle
    public let action: () -> Void
    
    public init(provider: SignInProviderType, labelType: SignInButtonLabelType? = .signIn, cornerStyle: SignInButtonCornerStyle = .radius(6), labelStyle: SignInButtonLabelStyle = .titleAndIcon, action: @escaping () -> Void) {
        self.provider = provider
        self.labelType = labelType
        self.cornerStyle = cornerStyle
        self.labelStyle = labelStyle
        self.action = action
    }
    
    public var body: some View {
        Group {
            switch labelStyle {
            case .iconOnly:
                iconOnlyButton
            case .titleAndIcon:
                titleAndIconButton
            }
        }
    }
    
    private var iconOnlyButton: some View {
        Button(action: action) {
            iconImage
                .foregroundColor(foregroundColor)
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .frame(minWidth: 42, minHeight: 42)
        .modifier(CornerStyleModifier(style: cornerStyle))
        .overlay(
            provider == .google ? RoundedRectangle(cornerRadius: cornerRadiusValue).stroke(Color.black, lineWidth: 0.5) : nil
        )
    }
    
    private var titleAndIconButton: some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 4) {
                    iconImage
                        .frame(width: 20, height: 20)
                    Text(buttonLabelText)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 180,
               maxWidth: .infinity,
               minHeight: 40,
               maxHeight: .infinity
        )
        .background(backgroundColor)
        .modifier(CornerStyleModifier(style: cornerStyle))
        .overlay(
            provider == .google ? RoundedRectangle(cornerRadius: cornerRadiusValue).stroke(Color.black, lineWidth: 0.5) : nil
        )
    }
    
    private var iconImage: some View {
        Group {
            switch provider {
            case .apple:
                Image("ic_apple", bundle: Bundle.module)
                    .resizable()
                    .renderingMode(.template)
            case .google:
                Image("ic_google", bundle: Bundle.module)
                    .resizable()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch provider {
        case .apple:
            return .black
        case .google:
            return .white
        }
    }
    
    private var foregroundColor: Color {
        switch provider {
        case .apple:
            return .white
        case .google:
            return .black
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
    
    private var cornerRadiusValue: CGFloat {
        switch cornerStyle {
        case .radius(let value):
            return CGFloat(value)
        case .capsule:
            return 1000
        }
    }
}

private struct CornerStyleModifier: ViewModifier {
    let style: SignInButtonCornerStyle
    func body(content: Content) -> some View {
        switch style {
        case .radius(let value):
            content.cornerRadius(CGFloat(value))
        case .capsule:
            content.clipShape(Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SignInButton(provider: .apple, labelStyle: .titleAndIcon, action: { print("apple titleAndIcon") })
            .frame(height: 44)
        SignInButton(provider: .apple, labelType: .continue, cornerStyle: .capsule, labelStyle: .iconOnly, action: { print("apple iconOnly") })
            .frame(width: 44, height: 44)
        SignInButton(provider: .google, cornerStyle: .radius(0), action: { print("google automatic") })
            .frame(height: 44)
        SignInButton(provider: .google, labelType: .signUp, cornerStyle: .capsule, labelStyle: .titleAndIcon, action: { print("google round") })
            .frame(height: 44)
        Spacer()
    }
    .padding(.horizontal)
}
