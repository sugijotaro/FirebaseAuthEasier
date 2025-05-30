//
//  ContentView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/28.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            List {
                Section("FirebaseAuthView") {
                    NavigationLink("Simple Auth View", destination: SimpleAuthView())
                    NavigationLink("Fully Customized Auth View", destination: CustomizedAuthView())
                    NavigationLink("Switch by Auth State", destination: AuthStateSwitchView())
                }
                Section("SignInButton") {
                    NavigationLink("SignInButton Customization", destination: SignInButtonSampleView())
                }
                Section("FirebaseAuthService") {
                    NavigationLink("Anonymous Sign In", destination: AnonymousSignInView())
                    NavigationLink("Sign Out", destination: SignOutView())
                    NavigationLink("Delete Account", destination: DeleteAccountView())
                    NavigationLink("Provider IDs & Link", destination: ProviderIDsAndLinkView())
                }
            }
            .navigationTitle("FirebaseAuthEasier")
        }
    }
}
