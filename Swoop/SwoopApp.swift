import SwiftUI
import SwiftData

@main
struct SwoopApp: App {

    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    init() {
        BackgroundRefreshService.registerTask()
        _ = WatchSyncService.shared  // activate WCSession
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme)
                .onAppear {
                    BackgroundRefreshService.scheduleNext()
                }
        }
        .modelContainer(for: DailySnapshot.self)
    }
}
