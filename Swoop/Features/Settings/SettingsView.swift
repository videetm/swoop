import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var snapshots: [DailySnapshot]

    @AppStorage("appearanceMode")       private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("sleepNeed")            private var sleepNeed: Double = 8.0
    @AppStorage("maxHROverride")        private var maxHROverride: Int = 190
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationHour")     private var notificationHour: Int = 8
    @AppStorage("notificationMinute")   private var notificationMinute: Int = 0

    @State private var showClearConfirm = false
    @State private var isRefreshing = false
    @State private var isBackfilling = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Form {
                    appearanceSection
                    healthSection
                    notificationsSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .tint(Color.swoopPurple)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("Clear all data?", isPresented: $showClearConfirm) {
            Button("Delete", role: .destructive) { clearAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(snapshots.count) snapshots. This cannot be undone.")
        }
    }

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding<AppearanceMode>(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Mode", selection: appearanceModeBinding) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Color.cardSurface)
    }

    private var healthSection: some View {
        Section("Health Profile") {
            HStack {
                Label("Sleep Need", systemImage: "moon.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Stepper(
                    value: $sleepNeed, in: 6.0...10.0, step: 0.5
                ) {
                    Text(String(format: "%.1fh", sleepNeed))
                        .foregroundStyle(Color.swoopBlue)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            HStack {
                Label("Max Heart Rate", systemImage: "heart.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Stepper(
                    value: $maxHROverride, in: 160...210, step: 1
                ) {
                    Text("\(maxHROverride) bpm")
                        .foregroundStyle(Color.swoopPink)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
        }
        .listRowBackground(Color.cardSurface)
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Daily Readiness Reminder", isOn: $notificationsEnabled)
                .foregroundStyle(.primary)
            if notificationsEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                bySettingHour: notificationHour,
                                minute: notificationMinute,
                                second: 0,
                                of: Date()
                            ) ?? Date()
                        },
                        set: {
                            notificationHour   = Calendar.current.component(.hour,   from: $0)
                            notificationMinute = Calendar.current.component(.minute, from: $0)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .foregroundStyle(.primary)
            }
        }
        .listRowBackground(Color.cardSurface)
    }

    private var dataSection: some View {
        Section("Data") {
            Button(action: triggerRefresh) {
                HStack {
                    Label(isRefreshing ? "Refreshing…" : "Refresh Now",
                          systemImage: "arrow.clockwise")
                    Spacer()
                    if isRefreshing { ProgressView().tint(.white) }
                }
                .foregroundStyle(.primary)
            }
            Button(action: triggerBackfill) {
                HStack {
                    Label(isBackfilling ? "Importing history…" : "Import Full History",
                          systemImage: "clock.arrow.circlepath")
                    Spacer()
                    if isBackfilling { ProgressView().tint(.white) }
                }
                .foregroundStyle(.primary)
            }
            .disabled(isBackfilling)
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        }
        .listRowBackground(Color.cardSurface)
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version").foregroundStyle(.primary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.primary.opacity(0.4))
            }
        }
        .listRowBackground(Color.cardSurface)
    }

    // MARK: - Actions

    private func triggerRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            try? await BackgroundRefreshService.refresh(
                container: modelContext.container,
                date: Date()
            )
            isRefreshing = false
        }
    }

    private func triggerBackfill() {
        guard !isBackfilling else { return }
        isBackfilling = true
        Task {
            await BackgroundRefreshService.backfill(
                container: modelContext.container,
                daysBack: 90
            )
            isBackfilling = false
        }
    }

    private func clearAllData() {
        snapshots.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
