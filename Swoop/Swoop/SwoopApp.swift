import SwiftUI
import SwiftData

@main
struct SwoopApp: App {

    init() {
        BackgroundRefreshService.registerTask()
        _ = WatchSyncService.shared  // activate WCSession
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    BackgroundRefreshService.scheduleNext()
                }
        }
        .modelContainer(for: DailySnapshot.self)
    }
}
