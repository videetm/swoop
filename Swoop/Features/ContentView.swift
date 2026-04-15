import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySnapshot.date, order: .reverse) private var snapshots: [DailySnapshot]
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @State private var hasPermission = false
    @State private var isRefreshing = false

    var today: DailySnapshot? { snapshots.first }

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme
    }

    var body: some View {
        Group {
            if hasPermission {
                mainTabs
            } else {
                OnboardingView(onComplete: {
                    hasPermission = true
                    triggerRefresh()
                })
            }
        }
        .preferredColorScheme(colorScheme)
        .task {
            let hk = HealthKitService()
            do {
                try await hk.requestPermissions()
                hasPermission = true
            } catch {
                hasPermission = false
            }
            if hasPermission && today == nil {
                triggerRefresh()
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            ReadinessRingView(snapshot: today, isRefreshing: isRefreshing, onRefresh: triggerRefresh)
                .tabItem { Label("Today", systemImage: "circle.fill") }

            HistoryView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color.swoopPurple)
    }

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
}
