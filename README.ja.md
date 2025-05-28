# FirebaseAuthEasier

[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

FirebaseAuthEasierは、Firebase Authentication（Apple/Googleサインイン）を**SwiftUIアプリに**簡単に組み込むためのSwiftパッケージです。

## 特徴
- Apple・GoogleサインインのUI/ロジックを一括提供
- シンプルなAPIとカスタマイズ可能なUIコンポーネント
- Firebase/GoogleSignIn公式SDKに依存
- iOS 15以降対応
- FirebaseAuthServiceによる柔軟な認証操作APIも提供
- SignInButtonコンポーネント単体でも利用可能。UIカスタマイズも柔軟

## 対応プラットフォーム
- iOS 15.0以降

## 依存パッケージ
- [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk)（v11.13.0以上）
- [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS)（v8.0.0以上）

## インストール方法
Swift Package Managerを利用して追加してください。

```
.package(url: "https://github.com/sugijotaro/FirebaseAuthEasier.git", from: "1.0.0")
```

Xcodeの場合：
1. 「File」→「Add Package Dependencies…」から上記URLを入力
2. 「FirebaseAuthEasier」を選択して追加

## 初期セットアップ
1. [Firebase公式ドキュメント](https://firebase.google.com/docs/ios/setup)に従い、GoogleService-Info.plistを追加
2. `AppDelegate`または`@main`の`App`でFirebaseを初期化
3. Firebase Consoleで「Sign in with Apple」「Sign in with Google」を有効化
4. Xcodeのプロジェクト設定で「Sign in with Apple」のCapabilityを追加
5. Google認証を利用する場合は、Google Cloud ConsoleでOAuthクライアントIDを取得し、Firebaseプロジェクトに設定

## 基本的な使い方
```swift
import SwiftUI
import FirebaseAuthEasier

struct ContentView: View {
    var body: some View {
        FirebaseAuthView()
    }
}
```

## FirebaseAuthViewのカスタマイズ
`FirebaseAuthView`は、以下のイニシャライザ引数で柔軟にカスタマイズできます。

```swift
public init(
    providers: [SignInProviderType]? = nil,
    labelType: SignInButtonLabelType = .signIn,
    @ViewBuilder content: @escaping () -> Content = { FirebaseAuthDefaultContentView() },
    onSignInStart: ((SignInProviderType) -> Void)? = nil,
    didSignIn: ((Result<AuthDataResult, Error>) -> Void)? = nil
)
```

### 引数の詳細とカスタマイズ例

#### providers（デフォルト: [.apple, .google]）
表示するサインインプロバイダーを指定します。
```swift
FirebaseAuthView(providers: [.apple]) // Appleサインインのみ
```

#### labelType（デフォルト: .signIn）
ボタンのラベル種別（.signIn, .signUp, .continue）を指定します。
```swift
FirebaseAuthView(labelType: .signUp)
```

#### content（デフォルト: FirebaseAuthDefaultContentView）
サインイン画面上部に表示する任意のViewをカスタマイズできます。
```swift
FirebaseAuthView {
    VStack {
        Text("Welcome!")
        Image(systemName: "person.circle")
    }
}
```

#### onSignInStart（デフォルト: nil）
サインイン処理開始時に呼ばれるクロージャ。プロバイダー種別を受け取れます。
```swift
FirebaseAuthView(onSignInStart: { provider in
    print("サインイン開始: \(provider)")
})
```

#### didSignIn（デフォルト: nil）
サインイン完了時に呼ばれるクロージャ。成功・失敗の結果を受け取れます。
```swift
FirebaseAuthView(didSignIn: { result in
    switch result {
    case .success(let authData):
        // サインイン成功時の処理
    case .failure(let error):
        // エラー処理
    }
})
```

### 組み合わせ例
```swift
FirebaseAuthView(
    providers: [.apple, .google],
    labelType: .continue,
    onSignInStart: { provider in
        // ローディング表示やログ出力など
    },
    didSignIn: { result in
        // サインイン完了時の処理
    }
) {
    VStack {
        Text("アプリへようこそ！")
        // 任意のカスタムView
    }
}
```

## FirebaseAuthServiceによる柔軟な認証操作
`FirebaseAuthService`は、サインイン・サインアウト・匿名認証・再認証・アカウント削除など、細かな認証操作を直接呼び出せる便利なAPIを提供しています。

```swift
import FirebaseAuthEasier

let authService = FirebaseAuthService()

// 匿名サインイン
authService.signInAnonymously { result in /* ... */ }

// サインアウト
authService.signOut { result in /* ... */ }

// 認証プロバイダのリンク
// アカウント削除
// ...など
```

## SignInButtonコンポーネントの単体利用・カスタマイズ
`SignInButton`はApple/Google用のサインインボタンUIを個別に利用でき、色・ラベル・角丸・枠線など細かくカスタマイズ可能です。

```swift
import FirebaseAuthEasier
import SwiftUI

SignInButton(
    provider: .apple,
    buttonStyle: .black,
    labelStyle: .titleAndIcon,
    labelType: .signIn,
    cornerStyle: .radius(12),
    hasBorder: true
) {
    // ボタン押下時処理
}
```

## コントリビューション
このプロジェクトへの貢献を歓迎しています！

- バグ報告や機能リクエストは[Issues](https://github.com/sugijotaro/FirebaseAuthEasier/issues)からお知らせください
- プルリクエストも大歓迎です
- 改善案やフィードバックがありましたら、お気軽にご連絡ください

## 注意事項
- Firebase/GoogleSignInのセットアップが正しく行われていない場合、認証が失敗します。
- Google認証にはGoogle Cloud Consoleでの設定が必要です。
- Appleサインインは実機でのみ動作します。
- Appleサインイン利用時は、必ずFirebase Consoleで有効化し、XcodeでCapability追加を行ってください。

## ライセンス
MIT © Jotaro Sugiyama
