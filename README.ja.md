# FirebaseAuthEasier

[English README](./README.md)

[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

FirebaseAuthEasier は、Apple・Google・匿名の Firebase Authentication を SwiftUI アプリへ組み込むためのパッケージです。カスタマイズ可能なサインイン UI、監視可能な認証セッション、コールバックと async/await のサービス API を提供します。

## 特徴

- `FirebaseAuthSession` が現在のユーザー、初回認証解決、連携済みプロバイダー、サインアウトの進行・失敗を管理
- `FirebaseAuthService` をすべての認証操作の単一ゲートウェイとして利用
- 匿名・Apple・Google・Credential・リンク・サインアウト・アカウント削除に async/await API を提供
- 既存のコールバック API も維持
- Apple 認証フローの状態をインスタンス単位かつ MainActor 上で管理し、重複開始を明示的なエラーとして拒否
- 複数ウィンドウの SwiftUI/iPad 向けに、Apple の提示ウィンドウと Google の提示 ViewController を注入可能
- 名前付き Firebase アプリ、テスト、明示的な初期化のため `Auth` を注入可能
- 最低対応は iOS 15 のまま維持し、新しい SwiftUI API は利用可能な OS で使用

## 要件

- iOS 15.0 以降
- Swift 6.0 以降
- firebase-ios-sdk 11.13.0 以上、13.0.0 未満
- GoogleSignIn-iOS 8.0.0 以上、10.0.0 未満

## インストール

Swift Package Manager で追加します。

```swift
.package(url: "https://github.com/sugijotaro/FirebaseAuthEasier.git", from: "2.0.0")
```

## Firebase のセットアップ

1. [Firebase の Apple プラットフォーム向けセットアップ](https://firebase.google.com/docs/ios/setup)に従って `GoogleService-Info.plist` を追加
2. `FirebaseAuthService`、`FirebaseAuthSession`、`FirebaseAuthView` を生成する前に `FirebaseApp.configure()` を実行
3. Firebase Console で利用する Apple・Google・匿名プロバイダーを有効化
4. Apple 認証を使う場合は Sign in with Apple Capability を追加
5. Google 認証を使う場合は Google OAuth クライアントを設定

引数なしの `FirebaseAuthService()` は、設定済みのデフォルト Firebase アプリを必要とします。未設定なら原因が分かる precondition メッセージで停止します。復旧可能な設定確認には `try FirebaseAuthService.configured()` を使ってください。名前付きアプリや依存注入には `FirebaseAuthService(auth:)` を使います。

```swift
import FirebaseAuth
import FirebaseAuthEasier

let service = FirebaseAuthService(auth: Auth.auth())
let session = FirebaseAuthSession(service: service)
```

## 監視可能な認証セッション

1 つのサービスと 1 つのセッションをアプリの認証状態の唯一の情報源として使います。`isAuthStateResolved` により、Firebase の初回リスナー通知前にサインアウト画面が一瞬表示されることを防げます。

```swift
import FirebaseAuth
import FirebaseAuthEasier
import SwiftUI

struct AuthGate: View {
    @StateObject private var session: FirebaseAuthSession
    private let authService: FirebaseAuthService

    init(auth: Auth = Auth.auth()) {
        let service = FirebaseAuthService(auth: auth)
        authService = service
        _session = StateObject(wrappedValue: FirebaseAuthSession(service: service))
    }

    var body: some View {
        Group {
            if !session.isAuthStateResolved {
                ProgressView("読み込み中…")
            } else if session.isSignedIn {
                VStack {
                    Text("サインイン済み")
                    Text(session.providerIDs.map(\.rawValue).joined(separator: ", "))
                    Button("サインアウト") {
                        Task {
                            do {
                                try await session.signOut()
                            } catch {
                                // session.signOutState のエラーを表示します。
                            }
                        }
                    }
                    .disabled(session.isSigningOut)
                }
            } else {
                FirebaseAuthView(authService: authService)
            }
        }
    }
}
```

主な状態は次のとおりです。

- `currentUser`、`isSignedIn`、`isAnonymous`
- `isAuthStateResolved`
- `providerIDs`、`usesProvider(_:)`
- `signOutState`、`isSigningOut`

セッションが解放されると Firebase リスナーも解除されます。状態変更は SwiftUI と厳密並行性に合わせて MainActor に隔離されています。

## FirebaseAuthView

最小構成は従来どおりです。

```swift
FirebaseAuthView()
```

既存のカスタマイズ API は維持し、サービスと提示コンテキストの任意注入を追加しています。

```swift
FirebaseAuthView(
    providers: [.apple, .google, .anonymous],
    labelType: .continue,
    termsOfServiceURL: URL(string: "https://example.com/terms"),
    privacyPolicyURL: URL(string: "https://example.com/privacy"),
    authService: authService,
    presentingViewControllerProvider: { mySceneRootViewController },
    onSignInStart: { provider in
        print("開始: \(provider)")
    },
    didSignIn: { result in
        print(result)
    }
) {
    VStack {
        Image(systemName: "person.circle")
        Text("ようこそ")
    }
}
```

デフォルトは Apple と Google、`.signIn` ラベル、規約リンクなし、`FirebaseAuthDefaultContentView` です。

## async/await サービス API

Apple/Google 認証と画面提示は UI に結びつくため、`FirebaseAuthService` は `@MainActor` です。

```swift
let service = FirebaseAuthService()

let anonymousResult = try await service.signInAnonymously()
let appleResult = try await service.startSignInWithApple()
let googleResult = try await service.startSignInWithGoogle(
    presentingViewController: viewController
)
let credentialResult = try await service.signInWithCredential(credential)
let linkedResult = try await service.linkCurrentUserWithCredential(credential)
try await service.signOut()
try await service.deleteAccount(presentingViewController: viewController)
```

Apple・Google のリンクにも async API があります。

```swift
let appleLink = try await service.startLinkWithApple()
let googleLink = try await service.startLinkWithGoogle(
    presentingViewController: viewController
)
```

`signOut(completion:)`、`signInAnonymously(completion:)`、各プロバイダーフローの completion など、既存クライアント向けコールバック形式も利用できます。

## 複数ウィンドウでの Apple 認証提示

デフォルトでは foreground-active なシーンを検索し、key window または表示中の window を使用します。複数ウィンドウで提示先を確実に決める場合は、対象シーンの window を注入します。

```swift
let service = FirebaseAuthService(
    auth: Auth.auth(),
    applePresentationAnchorProvider: { sceneWindow }
)
```

後から `setApplePresentationAnchorProvider(_:)` で差し替えることもできます。提示ウィンドウがなければ、Apple 認証は黙って止まらず `FirebaseAuthEasierError.missingApplePresentationAnchor` で完了します。同じサービスで Apple 認証を重複開始すると `authenticationFlowAlreadyInProgress` になります。

## SignInButton の単体利用

```swift
SignInButton(
    provider: .apple,
    buttonStyle: .black,
    labelStyle: .titleAndIcon,
    labelType: .signIn,
    cornerStyle: .radius(12),
    hasBorder: true,
    action: startAppleSignIn
)
```

## 移行ノート

- 既存のコールバック API と元の `FirebaseAuthView` 引数は維持されています。
- アプリごとに認証リスナーを再実装せず、共有 `FirebaseAuthSession` の利用を推奨します。
- 新規コードでは async/await API を推奨します。
- `FirebaseAuthService`、`FirebaseAuthSession`、`FirebaseAuthViewModel` は MainActor 隔離です。バックグラウンドからサービスを呼んでいたコードは `Task { @MainActor in ... }` などで MainActor に移してください。
- 引数なし initializer の前に Firebase を設定するか、`Auth` を注入してください。
- Apple・Google の対話フロー重複時は、共有 completion を上書きせず明示的に失敗します。
- 対話型の再認証では、Firebase の現在ユーザーを先に切り替えず credential だけを取得します。アカウント削除の再試行対象が新しく選んだ別アカウントへ変わることを防ぎます。
- `FirebaseAuthView` 内の未使用だった重複 `signInResult` は削除しました。表示結果は引き続き `FirebaseAuthViewModel.lastSignInResult`、公開完了通知は `didSignIn` です。

## 注意事項

- 各プロバイダーの設定、URL Scheme、Capability、有効な Firebase プロジェクト情報は引き続き必要です。
- Apple のシステム同意画面は自動テストで完結できないため、シミュレータに加えて Apple ID へサインインした実機でも確認してください。
- iOS 専用パッケージのため、macOS ホスト上の `swift test` は対応する検証方法ではありません。Xcode または `xcodebuild` で iOS Simulator を指定してパッケージ scheme を実行してください。

## ライセンス

MIT © Jotaro Sugiyama
