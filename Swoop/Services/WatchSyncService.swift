import WatchConnectivity
import Foundation

final class WatchSyncService: NSObject, WCSessionDelegate {

    static let shared = WatchSyncService()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(snapshot: DailySnapshot) {
        guard WCSession.default.isReachable else { return }
        let payload: [String: Any] = [
            "readinessScore": snapshot.readinessScore,
            "sleepScore": snapshot.sleepScore,
            "loadScore": snapshot.loadScore,
            "hrv": snapshot.hrv,
            "restingHR": snapshot.restingHR,
            "date": snapshot.date.timeIntervalSince1970
        ]
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
