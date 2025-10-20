// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseAuthEasier",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FirebaseAuthEasier",
            targets: ["FirebaseAuthEasier"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "11.13.0" ..< "13.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", "8.0.0" ..< "10.0.0"),
    ],
    targets: [
        .target(
            name: "FirebaseAuthEasier",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "googlesignin-iOS"),
            ]
        ),
    ]
)
