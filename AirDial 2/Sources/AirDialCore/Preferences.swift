import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case chinese = "zh-Hans", english = "en-US"
    public static func initial(preferred: [String]) -> Self {
        guard let first = preferred.first else { return .english }
        return first.hasPrefix("zh-Hans") || first == "zh-CN" || first == "zh-SG" ? .chinese : .english
    }
}

public final class Preferences {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public var enableOnLaunch: Bool {
        get { defaults.object(forKey: "enableOnLaunch") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enableOnLaunch") }
    }
    public var language: AppLanguage {
        get {
            defaults.string(forKey: "language").flatMap(AppLanguage.init(rawValue:))
                ?? AppLanguage.initial(preferred: Locale.preferredLanguages)
        }
        set { defaults.set(newValue.rawValue, forKey: "language") }
    }
}
