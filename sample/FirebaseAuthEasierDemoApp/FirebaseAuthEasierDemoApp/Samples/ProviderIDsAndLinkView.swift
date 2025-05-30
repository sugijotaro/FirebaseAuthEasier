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
        if let user = Auth.auth().currentUser {
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
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Link Apple Account") {
                    authService.startLinkWithApple { result in
                        switch result {
                        case .success(let authResult):
                            message = "Apple linked: \(authResult.user.uid)"
                            fetchProviderIDs()
                        case .failure(let error):
                            message = "Failed: \(error.localizedDescription)"
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Link Google Account") {
                    if let rootVC = getRootViewController() {
                        authService.startLinkWithGoogle(presentingViewController: rootVC) { result in
                            switch result {
                            case .success(let authResult):
                                message = "Google linked: \(authResult.user.uid)"
                                fetchProviderIDs()
                            case .failure(let error):
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
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear(perform: fetchProviderIDs)
    }
}

#Preview {
    ProviderIDsAndLinkView()
}
