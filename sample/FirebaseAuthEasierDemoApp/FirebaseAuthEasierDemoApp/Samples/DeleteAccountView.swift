//
//  DeleteAccountView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuthEasier

struct DeleteAccountView: View {
    @State private var message: String = ""
    private let authService = FirebaseAuthService()
    
    func getRootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.keyWindow?.rootViewController
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Button("Delete Account") {
                if let rootVC = getRootViewController() {
                    Task {
                        do {
                            try await authService.deleteAccount(presentingViewController: rootVC)
                            message = "Account deleted successfully."
                        } catch {
                            message = "Failed: \(error.localizedDescription)"
                        }
                    }
                } else {
                    message = "Could not get root view controller."
                }
            }
            .buttonStyle(.borderedProminent)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    DeleteAccountView()
}
