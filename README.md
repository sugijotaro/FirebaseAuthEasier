# FirebaseAuthEasier

[日本語READMEはこちら](./README.ja.md)

[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

FirebaseAuthEasier is a Swift package that makes it easy to integrate Firebase Authentication (Apple/Google sign-in) into **SwiftUI apps**.

<img width="493" alt="image" src="https://github.com/user-attachments/assets/1b9c8cc9-b199-416c-b507-9b562fdbbdb4" />

## Features
- Provides Apple & Google sign-in UI/logic in one package
- Simple API with customizable UI components
- Built on top of official Firebase/GoogleSignIn SDKs
- Supports iOS 15 and later
- Flexible authentication operation APIs via FirebaseAuthService
- SignInButton components can be used individually with flexible UI customization

## Supported Platforms
- iOS 15.0+

## Dependencies
- [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) (v11.13.0+)
- [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) (v8.0.0+)

## Installation
Add the package using Swift Package Manager.

```
.package(url: "https://github.com/sugijotaro/FirebaseAuthEasier.git", from: "1.0.0")
```

In Xcode:
1. Go to "File" → "Add Package Dependencies..." and enter the URL above
2. Select "FirebaseAuthEasier" to add

## Initial Setup
1. Follow the [Firebase official documentation](https://firebase.google.com/docs/ios/setup) to add GoogleService-Info.plist
2. Initialize Firebase in your `AppDelegate` or `@main` App
3. **Enable "Sign in with Apple" and "Sign in with Google" in Firebase Console**
4. **Add "Sign in with Apple" capability in Xcode project settings**
5. For Google authentication, obtain OAuth client ID from Google Cloud Console and configure it in your Firebase project

For more detailed setup instructions, see [this article (Japanese only)](https://qiita.com/sugijotaro/items/35daf9f6eba4d88c7bd2)

## Basic Usage
```swift
import SwiftUI
import FirebaseAuthEasier

struct ContentView: View {
    var body: some View {
        FirebaseAuthView()
    }
}
```

## Demo App

A demo app is available in the [`sample/FirebaseAuthEasierDemoApp`](sample/FirebaseAuthEasierDemoApp) directory.

You can use this app to see FirebaseAuthEasier in action and as a reference for integration.

## FirebaseAuthView Customization
`FirebaseAuthView` can be flexibly customized with the following initializer parameters:

```swift
public init(
    providers: [SignInProviderType]? = nil,
    labelType: SignInButtonLabelType = .signIn,
    termsOfServiceURL: URL? = nil,
    privacyPolicyURL: URL? = nil,
    onSignInStart: ((SignInProviderType) -> Void)? = nil,
    didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content = { FirebaseAuthDefaultContentView() }
)
```

### Parameter Details and Customization Examples

#### providers (Default: [.apple, .google])
Specify which sign-in providers to display.
```swift
FirebaseAuthView(providers: [.apple]) // Apple sign-in only
```

#### labelType (Default: .signIn)
Specify the button label type (.signIn, .signUp, .continue).
```swift
FirebaseAuthView(labelType: .signUp)
```

#### termsOfServiceURL (Default: nil)
URL for Terms of Service. If provided, a legal message will be displayed at the bottom of the sign-in screen.
```swift
FirebaseAuthView(termsOfServiceURL: URL(string: "https://example.com/terms"))
```

#### privacyPolicyURL (Default: nil)
URL for Privacy Policy. If provided, a legal message will be displayed at the bottom of the sign-in screen.
```swift
FirebaseAuthView(privacyPolicyURL: URL(string: "https://example.com/privacy"))
```

#### content (Default: FirebaseAuthDefaultContentView)
Customize the view displayed at the top of the sign-in screen.
```swift
FirebaseAuthView {
    VStack {
        Text("Welcome!")
        Image(systemName: "person.circle")
    }
}
```

#### onSignInStart (Default: nil)
Closure called when sign-in process starts. Receives the provider type.
```swift
FirebaseAuthView(onSignInStart: { provider in
    print("Sign-in started: \(provider)")
})
```

#### didSignIn (Default: nil)
Closure called when sign-in completes. Receives success/failure result.
```swift
FirebaseAuthView(didSignIn: { result in
    switch result {
    case .success(let authData):
        // Handle successful sign-in
    case .failure(let error):
        // Handle error
    }
})
```

### Combined Example
```swift
struct ContentView: View {
    var body: some View {
        FirebaseAuthView(
            providers: [.apple, .google],
            labelType: .continue,
            termsOfServiceURL: URL(string: "https://example.com/terms")!,
            privacyPolicyURL: URL(string: "https://example.com/privacy")!,
            onSignInStart: { provider in
                print("Sign-in started with provider: \(provider)")
            },
            didSignIn: { result in
                switch result {
                case .success(let authResult):
                    print("Sign-in successful")
                case .failure(let error):
                    print("Sign-in failed: \(error.localizedDescription)")
                }
            }
        ) {
            VStack {
                Image(systemName: "person.circle")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Welcome!")
            }
        }
    }
}
```

## Flexible Authentication Operations with FirebaseAuthService
`FirebaseAuthService` provides convenient APIs for detailed authentication operations such as sign-in, sign-out, anonymous authentication, re-authentication, and account deletion.

```swift
import FirebaseAuthEasier

let authService = FirebaseAuthService()

// Anonymous sign-in
authService.signInAnonymously { result in /* ... */ }

// Sign-out
authService.signOut { result in /* ... */ }

// Link authentication providers
// Account deletion
// ...and more
```

## Individual Use and Customization of SignInButton Component
`SignInButton` provides Apple/Google sign-in button UI that can be used individually, with fine-grained customization for colors, labels, corner radius, borders, and more.

```swift
import SwiftUI
import FirebaseAuthEasier

SignInButton(
    provider: .apple,
    buttonStyle: .black,
    labelStyle: .titleAndIcon,
    labelType: .signIn,
    cornerStyle: .radius(12),
    hasBorder: true
) {
    // Button tap handling
}
```

## Contributing
We welcome contributions to this project!

- Report bugs or request features via [Issues](https://github.com/sugijotaro/FirebaseAuthEasier/issues)
- Pull requests are very welcome
- Feel free to reach out with improvement suggestions or feedback

## Important Notes
- Authentication will fail if Firebase/GoogleSignIn setup is not configured correctly
- Google authentication requires configuration in Google Cloud Console
- Apple sign-in only works on physical devices
- When using Apple sign-in, make sure to enable it in Firebase Console and add the capability in Xcode

## License
MIT © Jotaro Sugiyama
