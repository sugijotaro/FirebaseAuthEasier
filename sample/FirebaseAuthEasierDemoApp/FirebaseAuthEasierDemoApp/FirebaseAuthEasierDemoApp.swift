//
//  FirebaseAuthEasierDemoApp.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/28.
//

import SwiftUI
import Firebase

@main
struct FirebaseAuthEasierDemoApp: App {
    init(){
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
