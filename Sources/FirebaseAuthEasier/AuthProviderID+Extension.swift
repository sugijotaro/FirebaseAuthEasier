//
//  AuthProviderID+Extension.swift
//  FirebaseAuthEasier
//
//  Created by Jotaro Sugiyama on 2025/05/25.
//

import Foundation
import FirebaseAuth

public extension FirebaseAuth.AuthProviderID {
    static func from(_ rawValue: String) -> AuthProviderID? {
        switch rawValue {
        case AuthProviderID.apple.rawValue: return .apple
        case AuthProviderID.email.rawValue: return .email
        case AuthProviderID.facebook.rawValue: return .facebook
        case AuthProviderID.gameCenter.rawValue: return .gameCenter
        case AuthProviderID.gitHub.rawValue: return .gitHub
        case AuthProviderID.google.rawValue: return .google
        case AuthProviderID.phone.rawValue: return .phone
        case rawValue: return .custom(rawValue)
        default: return nil
        }
    }
}
