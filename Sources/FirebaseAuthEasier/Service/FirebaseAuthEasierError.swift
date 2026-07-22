//
//  FirebaseAuthEasierError.swift
//  FirebaseAuthEasier
//

import Foundation

public enum FirebaseAuthEasierError: LocalizedError, Equatable, Sendable {
    case firebaseNotConfigured
    case currentUserNotFound
    case missingCredential
    case missingGoogleClientID
    case invalidGoogleCredential
    case invalidAppleCredential
    case nonceGenerationFailed(Int32)
    case missingApplePresentationAnchor
    case missingAuthenticationPresentationContext
    case authenticationFlowAlreadyInProgress
    case unexpectedAuthorizationCallback
    case missingAuthenticationResult

    public var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            "Firebase is not configured. Call FirebaseApp.configure() before creating FirebaseAuthService, or inject an Auth instance with init(auth:)."
        case .currentUserNotFound:
            "No Firebase user is currently signed in."
        case .missingCredential:
            "The authentication provider did not return a credential."
        case .missingGoogleClientID:
            "The configured Firebase app does not contain a Google client ID."
        case .invalidGoogleCredential:
            "Google Sign-In did not return valid user credentials."
        case .invalidAppleCredential:
            "Sign in with Apple did not return a valid identity token."
        case .nonceGenerationFailed(let status):
            "Unable to generate a secure Sign in with Apple nonce (OSStatus: \(status))."
        case .missingApplePresentationAnchor:
            "No active window is available to present Sign in with Apple. Inject an Apple presentation anchor provider for this scene."
        case .missingAuthenticationPresentationContext:
            "No active view controller is available to present authentication. Inject a presentation provider for this scene."
        case .authenticationFlowAlreadyInProgress:
            "Another authentication flow is already in progress on this service."
        case .unexpectedAuthorizationCallback:
            "The authorization callback did not match the active authentication flow."
        case .missingAuthenticationResult:
            "Firebase Authentication completed without returning a result."
        }
    }
}
