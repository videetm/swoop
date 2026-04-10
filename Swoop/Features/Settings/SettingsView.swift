import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var birthYear: Int = UserSettings.shared.birthYear
    @State private var sleepNeed: Double = UserSettings.shared.sleepNeedHours
    @State private var showResetConfirm = false

    var estimatedMaxHR: Int { Int(220 - Double(Calendar.current.component(.year, from: Date()) - birthYear)) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()
                Form {
                    Section {
                        Stepper("Birth Year: \(birthYear)", value: $birthYear, in: 1940...2010)
                            .onChange(of: birthYear) { UserSettings.shared.birthYear = $0 }
                        Text("Estimated max HR: \(estimatedMaxHR) bpm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Heart Rate Zones")
                    }

                    Section {
                        Stepper(String(format: "Sleep Need: %.1f hours", sleepNeed),
                                value: $sleepNeed, in: 5...10, step: 0.5)
                            .onChange(of: sleepNeed) { UserSettings.shared.sleepNeedHours = $0 }
                    } header: {
                        Text("Sleep")
                    }

                    Section {
                        Button("Reset All Data", role: .destructive) {
                            showResetConfirm = true
                        }
                    } header: {
                        Text("Data")
                    }
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog("Delete all SWOOP data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Delete All Data", role: .destructive) { resetAllData() }
            }
        }
    }

    private func resetAllData() {
        try? modelContext.delete(model: DailySnapshot.self)
    }
}
