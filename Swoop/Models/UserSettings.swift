import Foundation
import SwiftUI

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

    /// Stored max HR override; defaults to age-based formula if never set.
    var maxHR: Double {
        let stored = defaults.integer(forKey: "maxHROverride")
        if stored > 0 { return Double(stored) }
        let age = Calendar.current.component(.year, from: Date()) - birthYear
        return max(220.0 - Double(age), 160.0)
    }

    var maxHROverride: Int {
        get { defaults.integer(forKey: "maxHROverride") == 0 ? 190 : defaults.integer(forKey: "maxHROverride") }
        set { defaults.set(newValue, forKey: "maxHROverride") }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: defaults.string(forKey: "appearanceMode") ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: "appearanceMode") }
    }

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: "notificationsEnabled") }
        set { defaults.set(newValue, forKey: "notificationsEnabled") }
    }

    var notificationHour: Int {
        get { defaults.integer(forKey: "notificationHour") == 0 ? 8 : defaults.integer(forKey: "notificationHour") }
        set { defaults.set(newValue, forKey: "notificationHour") }
    }

    var notificationMinute: Int {
        get { defaults.integer(forKey: "notificationMinute") }
        set { defaults.set(newValue, forKey: "notificationMinute") }
    }
}
