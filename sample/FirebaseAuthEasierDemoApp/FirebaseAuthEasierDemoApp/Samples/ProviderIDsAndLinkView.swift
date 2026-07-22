//
//  ProviderIDsAndLinkView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuth
import FirebaseAuthEasier

struct ProviderIDsAndLinkView: View {
    @State private var providerIDs: [AuthProviderID] = []
    @State private var message: String = ""
    private let authService = FirebaseAuthService()
    
    func getRootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.keyWindow?.rootViewController
    }
    
    func fetchProviderIDs() {
        if let user = authService.currentUser {
            providerIDs = FirebaseAuthService.providerIDs(for: user)
        } else {
            providerIDs = []
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Refresh Provider IDs") {
                fetchProviderIDs()
            }
            Text("Current Provider IDs: \(providerIDs.map { $0.rawValue }.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Link Apple Account") {
                    Task {
                        do {
                            let authResult = try await authService.startLinkWithApple()
                            message = "Apple linked: \(authResult.user.uid)"
                            fetchProviderIDs()
                        } catch {
                            message = "Failed: \(error.localizedDescription)"
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Link Google Account") {
                    if let rootVC = getRootViewController() {
                        Task {
                            do {
                                let authResult = try await authService.startLinkWithGoogle(
                                    presentingViewController: rootVC
                                )
                                message = "Google linked: \(authResult.user.uid)"
                                fetchProviderIDs()
                            } catch {
                                message = "Failed: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        message = "Could not get root view controller."
                    }
                }
                .buttonStyle(.bordered)
            }
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear(perform: fetchProviderIDs)
    }
}

#Preview {
    ProviderIDsAndLinkView()
}
