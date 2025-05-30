//
//  SignInButtonSampleView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuthEasier

struct SignInButtonSampleView: View {
    @State private var provider: SignInProviderType = .apple
    @State private var buttonStyle: SignInButtonStyle = .black
    @State private var labelStyle: SignInButtonLabelStyle = .automatic
    @State private var labelType: SignInButtonLabelType = .signIn
    @State private var cornerStyle: SignInButtonCornerStyle = .radius(6)
    @State private var hasBorder: Bool = false
    @State private var cornerRadius: Double = 6
    @State private var width: Double = 320
    @State private var height: Double = 44
    
    var body: some View {
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
            .frame(maxHeight: .infinity)
            
            VStack(spacing: 12) {
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
}

#Preview {
    SignInButtonSampleView()
}
