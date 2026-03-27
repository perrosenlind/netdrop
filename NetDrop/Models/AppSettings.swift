import SwiftUI

@Observable
class AppSettings {
    var appearanceMode: AppearanceMode {
        didSet { save() }
    }

    var backupDirectory: String {
        didSet { save() }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    static var defaultBackupDirectory: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("NetDrop/backups", isDirectory: true).path
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: raw) ?? .system
        self.backupDirectory = UserDefaults.standard.string(forKey: "backupDirectory") ?? AppSettings.defaultBackupDirectory
    }

    private func save() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        UserDefaults.standard.set(backupDirectory, forKey: "backupDirectory")
    }
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
