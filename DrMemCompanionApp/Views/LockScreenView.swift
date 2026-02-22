import SwiftUI

struct LockScreenView: View {
    let biometricService: BiometricService
    @State private var authFailed: Bool = false
    @State private var isAuthenticating: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(DrMemTheme.terracotta)
                .symbolEffect(.pulse, isActive: isAuthenticating)

            VStack(spacing: 8) {
                Text("Dr. Mem")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(DrMemTheme.darkText)

                Text("Unlock to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if authFailed {
                Text("Authentication failed. Try again.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button {
                authenticate()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.title2)
                    Text("Unlock")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(DrMemTheme.terracotta, in: Capsule())
                .shadow(color: DrMemTheme.terracotta.opacity(0.3), radius: 8, y: 4)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isAuthenticating)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { WarmBackground() }
        .onAppear {
            authenticate()
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authFailed = false

        Task {
            let success = await biometricService.authenticate()
            isAuthenticating = false
            if !success {
                authFailed = true
            }
        }
    }
}
