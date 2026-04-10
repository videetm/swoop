import Foundation

final class UserSettings {
    static let shared = UserSettings()
    private init() {}

    private let defaults = UserDefaults.standard

    var birthYear: Int {
        get { defaults.integer(forKey: "birthYear") == 0 ? 1990 : defaults.integer(forKey: "birthYear") }
        set { defaults.set(newValue, forKey: "birthYear") }
    }

    var sleepNeedHours: Double {
        get { defaults.double(forKey: "sleepNeed") == 0 ? 8.0 : defaults.double(forKey: "sleepNeed") }
        set { defaults.set(newValue, forKey: "sleepNeed") }
    }

    var maxHR: Double {
        let age = Calendar.current.component(.year, from: Date()) - birthYear
        return max(220.0 - Double(age), 160.0)
    }
}
