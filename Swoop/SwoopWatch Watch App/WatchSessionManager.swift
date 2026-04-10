import WatchConnectivity
import Foundation

@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {

    static let shared = WatchSessionManager()

    var readinessScore: Double = 0
    var sleepScore: Double = 0
    var loadScore: Double = 0
    var hrv: Double = 0

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.readinessScore = message["readinessScore"] as? Double ?? 0
            self.sleepScore = message["sleepScore"] as? Double ?? 0
            self.loadScore = message["loadScore"] as? Double ?? 0
            self.hrv = message["hrv"] as? Double ?? 0
        }
    }
}
