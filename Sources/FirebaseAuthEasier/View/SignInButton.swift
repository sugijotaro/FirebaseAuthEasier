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

public enum SignInButtonStyle {
    case black
    case white
}

public enum SignInButtonLabelStyle {
    @available(iOS 16.0, *)
    case automatic
    case titleAndIcon
    case iconOnly
}

public enum SignInButtonLabelType {
    case signIn
    case signUp
    case `continue`
}

public enum SignInButtonCornerStyle {
    case none
    case radius(Int)
}

public struct SignInButton: View {
    public let provider: SignInProviderType
    public let buttonStyle: SignInButtonStyle
    public let labelStyle: SignInButtonLabelStyle
    public let labelType: SignInButtonLabelType
    public let cornerStyle: SignInButtonCornerStyle
    public let hasBorder: Bool
    public let action: () -> Void
    
    public init(
        provider: SignInProviderType,
        buttonStyle: SignInButtonStyle = .black,
        labelStyle: SignInButtonLabelStyle? = nil,
        labelType: SignInButtonLabelType = .signIn,
        cornerStyle: SignInButtonCornerStyle = .radius(6),
        hasBorder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.provider = provider
        self.buttonStyle = buttonStyle
        if let labelStyle = labelStyle {
            self.labelStyle = labelStyle
        } else {
            if #available(iOS 16.0, *) {
                self.labelStyle = .automatic
            } else {
                self.labelStyle = .titleAndIcon
            }
        }
        self.labelType = labelType
        self.cornerStyle = cornerStyle
        self.hasBorder = hasBorder
        self.action = action
    }
    
    public var body: some View {
        Group {
            if #available(iOS 16.0, *), labelStyle == .automatic {
                ViewThatFits {
                    titleAndIconButton
                    iconOnlyButton
                }
            } else {
                switch labelStyle {
                case .iconOnly:
                    iconOnlyButton
                case .titleAndIcon:
                    titleAndIconButton
                default:
                    titleAndIconButton
                }
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
        .frame(minWidth: 40, minHeight: 40)
        .modifier(CornerStyleModifier(style: cornerStyle))
        .overlay(
            hasBorder ? RoundedRectangle(cornerRadius: cornerRadiusValue).strokeBorder(borderColor, lineWidth: 1) : nil
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
            hasBorder ? RoundedRectangle(cornerRadius: cornerRadiusValue).strokeBorder(borderColor, lineWidth: 1) : nil
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
        switch buttonStyle {
        case .black:
            return .black
        case .white:
            return .white
        }
    }
    
    private var foregroundColor: Color {
        switch buttonStyle {
        case .black:
            return .white
        case .white:
            return .black
        }
    }
    
    private var borderColor: Color {
        switch buttonStyle {
        case .black:
            return .white
        case .white:
            return .black
        }
    }
    
    private var buttonLabelText: String {
        switch provider {
        case .apple:
            switch labelType {
            case .signIn:
                return NSLocalizedString("Sign in with Apple", bundle: Bundle.module, comment: "")
            case .signUp:
                return NSLocalizedString("Sign up with Apple", bundle: Bundle.module, comment: "")
            case .continue:
                return NSLocalizedString("Continue with Apple", bundle: Bundle.module, comment: "")
            }
        case .google:
            switch labelType {
            case .signIn:
                return NSLocalizedString("Sign in with Google", bundle: Bundle.module, comment: "")
            case .signUp:
                return NSLocalizedString("Sign up with Google", bundle: Bundle.module, comment: "")
            case .continue:
                return NSLocalizedString("Continue with Google", bundle: Bundle.module, comment: "")
            }
        }
    }
    
    private var cornerRadiusValue: CGFloat {
        switch cornerStyle {
        case .none:
            return CGFloat(0)
        case .radius(let value):
            return CGFloat(value)
        }
    }
}

private struct CornerStyleModifier: ViewModifier {
    let style: SignInButtonCornerStyle
    func body(content: Content) -> some View {
        switch style {
        case .none:
            content.cornerRadius(CGFloat(0))
        case .radius(let value):
            content.cornerRadius(CGFloat(value))
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var provider: SignInProviderType = .apple
    @Previewable @State var buttonStyle: SignInButtonStyle = .black
    @Previewable @State var labelStyle: SignInButtonLabelStyle = .automatic
    @Previewable @State var labelType: SignInButtonLabelType = .signIn
    @Previewable @State var cornerStyle: SignInButtonCornerStyle = .radius(6)
    @Previewable @State var hasBorder: Bool = false
    @Previewable @State var cornerRadius: Double = 6
    @Previewable @State var width: Double = 320
    @Previewable @State var height: Double = 44
    
    VStack(spacing: 16) {
        SignInButton(
            provider: provider,
            buttonStyle: buttonStyle,
            labelStyle: labelStyle,
            labelType: labelType,
            cornerStyle: cornerStyle,
            hasBorder: hasBorder,
            action: {}
        )
        .frame(width: width, height: height)
        
        VStack {
            Picker("Provider", selection: $provider) {
                Text("Apple").tag(SignInProviderType.apple)
                Text("Google").tag(SignInProviderType.google)
            }
            .pickerStyle(.segmented)
            
            Picker("Button Style", selection: $buttonStyle) {
                Text("Black").tag(SignInButtonStyle.black)
                Text("White").tag(SignInButtonStyle.white)
            }
            .pickerStyle(.segmented)
            
            Picker("Label Style", selection: $labelStyle) {
                Text("Automatic").tag(SignInButtonLabelStyle.automatic)
                Text("Title & Icon").tag(SignInButtonLabelStyle.titleAndIcon)
                Text("Icon Only").tag(SignInButtonLabelStyle.iconOnly)
            }
            .pickerStyle(.segmented)
            
            Picker("Label Type", selection: $labelType) {
                Text("Sign In").tag(SignInButtonLabelType.signIn)
                Text("Sign Up").tag(SignInButtonLabelType.signUp)
                Text("Continue").tag(SignInButtonLabelType.continue)
            }
            .pickerStyle(.segmented)
            
            Toggle("Has Border", isOn: $hasBorder)
            
            if case .radius = cornerStyle {
                HStack {
                    Text("Corner Radius: \(Int(cornerRadius))")
                    Slider(value: $cornerRadius, in: 0...200, step: 1) { _ in
                        cornerStyle = .radius(Int(cornerRadius))
                    }
                }
            }
            HStack {
                Text("Width: \(Int(width))")
                Slider(value: $width, in: 40...400, step: 1)
            }
            HStack {
                Text("Height: \(Int(height))")
                Slider(value: $height, in: 40...400, step: 1)
            }
        }
        .padding(.horizontal)
    }
}
