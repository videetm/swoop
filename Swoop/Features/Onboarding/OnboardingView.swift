import SwiftUI

struct OnboardingView: View {

    let onComplete: () -> Void
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text("SWOOP")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(Color.swoopPurple)

                    Text("Your body. Your data.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 16) {
                    permissionRow(icon: "heart.fill", color: .swoopPink,
                                  title: "Heart Rate & HRV",
                                  description: "Measures your readiness and stress levels")
                    permissionRow(icon: "moon.fill", color: .swoopBlue,
                                  title: "Sleep",
                                  description: "Tracks sleep duration and quality")
                    permissionRow(icon: "bolt.fill", color: .swoopGreen,
                                  title: "Workouts",
                                  description: "Calculates your daily training load")
                }
                .padding(.horizontal, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.swoopPink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button(action: requestPermissions) {
                    HStack {
                        if isRequesting {
                            ProgressView().tint(.white)
                        }
                        Text(isRequesting ? "Requesting..." : "Connect Health Data")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.swoopPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func permissionRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(description).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    private func requestPermissions() {
        isRequesting = true
        Task {
            do {
                try await HealthKitService().requestPermissions()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
                isRequesting = false
            }
        }
    }
}
