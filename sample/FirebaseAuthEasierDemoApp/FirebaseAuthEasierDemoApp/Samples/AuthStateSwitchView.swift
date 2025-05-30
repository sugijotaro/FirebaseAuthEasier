//
//  AuthStateSwitchView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuth
import FirebaseAuthEasier

class AuthStateSwitchViewModel: ObservableObject {
    @Published var currentUser: FirebaseAuth.User? = nil
    private let authService = FirebaseAuthService()
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = authService.addAuthStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }
    deinit {
        if let handle = handle {
            authService.removeAuthStateDidChangeListener(handle)
        }
    }
    func signOut() {
        authService.signOut { _ in }
    }
}

struct AuthStateSwitchView: View {
    @StateObject private var viewModel = AuthStateSwitchViewModel()
    
    var body: some View {
        Group {
            if viewModel.currentUser == nil {
                FirebaseAuthView()
            } else {
                VStack(spacing: 16) {
                    Text("You are signed in!")
                        .font(.title2)
                    Button("Sign Out") {
                        viewModel.signOut()
                    }
                }
            }
        }
    }
}

#Preview {
    AuthStateSwitchView()
}
