//
//  MainActorTransfer.swift
//  FirebaseAuthEasier
//

/// Keeps legacy SDK result objects on the main actor while satisfying continuation transfer
/// checking. The wrapped value is created, resumed, and consumed only on `MainActor`.
struct MainActorTransfer<Value>: @unchecked Sendable {
    let value: Value
}

@MainActor
func resumeMainActorContinuation<Value>(
    _ continuation: CheckedContinuation<MainActorTransfer<Value>, Error>,
    with result: Result<Value, Error>
) {
    switch result {
    case .success(let value):
        continuation.resume(returning: MainActorTransfer(value: value))
    case .failure(let error):
        continuation.resume(throwing: error)
    }
}
