import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {

    // MARK: - Appearance

    var theme: AppTheme {
        get { access(keyPath: \.theme); return _theme }
        set {
            withMutation(keyPath: \.theme) { _theme = newValue }
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.theme)
            AppIconService.apply(theme: newValue)
        }
    }
    private var _theme: AppTheme

    var weekStartsOnMonday: Bool {
        get { access(keyPath: \.weekStartsOnMonday); return _weekStartsOnMonday }
        set { withMutation(keyPath: \.weekStartsOnMonday) { _weekStartsOnMonday = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.weekStartsOnMonday) }
    }
    private var _weekStartsOnMonday: Bool

    // MARK: - Cut-off time

    var cutoffHour: Int {
        get { access(keyPath: \.cutoffHour); return _cutoffHour }
        set { withMutation(keyPath: \.cutoffHour) { _cutoffHour = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.cutoffHour) }
    }
    private var _cutoffHour: Int

    var cutoffMinute: Int {
        get { access(keyPath: \.cutoffMinute); return _cutoffMinute }
        set { withMutation(keyPath: \.cutoffMinute) { _cutoffMinute = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.cutoffMinute) }
    }
    private var _cutoffMinute: Int

    // MARK: - Reminders

    var morningReminderEnabled: Bool {
        get { access(keyPath: \.morningReminderEnabled); return _morningReminderEnabled }
        set { withMutation(keyPath: \.morningReminderEnabled) { _morningReminderEnabled = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.morningReminderEnabled) }
    }
    private var _morningReminderEnabled: Bool

    var morningReminderTime: Date {
        get { access(keyPath: \.morningReminderTime); return _morningReminderTime }
        set { withMutation(keyPath: \.morningReminderTime) { _morningReminderTime = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.morningReminderTime) }
    }
    private var _morningReminderTime: Date

    var middayReminderEnabled: Bool {
        get { access(keyPath: \.middayReminderEnabled); return _middayReminderEnabled }
        set { withMutation(keyPath: \.middayReminderEnabled) { _middayReminderEnabled = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.middayReminderEnabled) }
    }
    private var _middayReminderEnabled: Bool

    var middayReminderTime: Date {
        get { access(keyPath: \.middayReminderTime); return _middayReminderTime }
        set { withMutation(keyPath: \.middayReminderTime) { _middayReminderTime = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.middayReminderTime) }
    }
    private var _middayReminderTime: Date

    var eveningReminderEnabled: Bool {
        get { access(keyPath: \.eveningReminderEnabled); return _eveningReminderEnabled }
        set { withMutation(keyPath: \.eveningReminderEnabled) { _eveningReminderEnabled = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.eveningReminderEnabled) }
    }
    private var _eveningReminderEnabled: Bool

    var eveningReminderTime: Date {
        get { access(keyPath: \.eveningReminderTime); return _eveningReminderTime }
        set { withMutation(keyPath: \.eveningReminderTime) { _eveningReminderTime = newValue }
              UserDefaults.standard.set(newValue, forKey: Keys.eveningReminderTime) }
    }
    private var _eveningReminderTime: Date

    // MARK: - Init

    init() {
        let d = UserDefaults.standard
        // Date is not a valid plist type — register(defaults:) silently drops Date values.
        // Time fallbacks are handled at read time via readDate(from:key:default:).
        d.register(defaults: [
            Keys.theme:                  AppTheme.orange.rawValue,
            Keys.weekStartsOnMonday:     false,
            Keys.cutoffHour:             21,
            Keys.cutoffMinute:           0,
            Keys.morningReminderEnabled: false,
            Keys.middayReminderEnabled:  false,
            Keys.eveningReminderEnabled: false,
        ])

        _theme               = AppTheme(rawValue: d.string(forKey: Keys.theme) ?? "") ?? .orange
        _weekStartsOnMonday  = d.bool(forKey: Keys.weekStartsOnMonday)
        _cutoffHour          = d.integer(forKey: Keys.cutoffHour)
        _cutoffMinute        = d.integer(forKey: Keys.cutoffMinute)
        _morningReminderEnabled = d.bool(forKey: Keys.morningReminderEnabled)
        _morningReminderTime    = Self.readDate(from: d, key: Keys.morningReminderTime, defaultHour: 8)
        _middayReminderEnabled  = d.bool(forKey: Keys.middayReminderEnabled)
        _middayReminderTime     = Self.readDate(from: d, key: Keys.middayReminderTime,  defaultHour: 12)
        _eveningReminderEnabled = d.bool(forKey: Keys.eveningReminderEnabled)
        _eveningReminderTime    = Self.readDate(from: d, key: Keys.eveningReminderTime, defaultHour: 20)
    }

    // MARK: - Private

    private enum Keys {
        static let theme                 = "appTheme"
        static let weekStartsOnMonday    = "weekStartsOnMonday"
        static let cutoffHour            = "cutoffHour"
        static let cutoffMinute          = "cutoffMinute"
        static let morningReminderEnabled = "morningReminderEnabled"
        static let morningReminderTime   = "morningReminderTime"
        static let middayReminderEnabled = "middayReminderEnabled"
        static let middayReminderTime    = "middayReminderTime"
        static let eveningReminderEnabled = "eveningReminderEnabled"
        static let eveningReminderTime   = "eveningReminderTime"
    }

    private static func readDate(from defaults: UserDefaults, key: String, defaultHour: Int) -> Date {
        (defaults.object(forKey: key) as? Date) ?? defaultTime(hour: defaultHour)
    }

    private static func defaultTime(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
