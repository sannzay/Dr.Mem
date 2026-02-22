import LocalAuthentication

@Observable
class BiometricService {
    var isUnlocked: Bool = false
    var isLockEnabled: Bool = false

    init() {
        isLockEnabled = UserDefaults.standard.bool(forKey: "appLockEnabled")
        if !isLockEnabled { isUnlocked = true }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        let policy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            policy = .deviceOwnerAuthentication
        } else {
            isUnlocked = true
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: "Unlock Dr. Mem"
            )
            isUnlocked = success
            return success
        } catch {
            return false
        }
    }

    func toggleLock(_ enabled: Bool) {
        isLockEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "appLockEnabled")
        if !enabled {
            isUnlocked = true
        } else {
            Task {
                let success = await authenticate()
                if !success {
                    isLockEnabled = false
                    UserDefaults.standard.set(false, forKey: "appLockEnabled")
                }
            }
        }
    }
}
