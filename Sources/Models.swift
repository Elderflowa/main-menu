import SwiftUI

enum LaunchMethod: String, Codable, CaseIterable, Identifiable {
    case auto, urlScheme, shortcut
    var id: String { rawValue }
    var label: String {
        switch self {
        case .auto: return "Auto (URL scheme, then Shortcut)"
        case .urlScheme: return "URL scheme only"
        case .shortcut: return "Shortcut only"
        }
    }
}

struct Game: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var genre: String = ""
    var colorHex: String = "4A74E0"
    var symbol: String = "gamecontroller.fill"
    var iconURL: String? = nil
    var artURL: String? = nil
    /// True once the user picked art by hand; automatic fetching never touches it.
    var artManual: Bool? = nil
    var uriScheme: String = ""
    var altSchemes: [String] = []
    var bundleID: String = ""
    var shortcutName: String = ""
    var method: LaunchMethod = .auto
    var lastPlayed: Date? = nil
    var launches: Int = 0

    var methodSummary: String {
        let hasScheme = !uriScheme.trimmingCharacters(in: .whitespaces).isEmpty
        let hasShortcut = !shortcutName.trimmingCharacters(in: .whitespaces).isEmpty
        switch method {
        case .urlScheme: return hasScheme ? "URL scheme" : "No URL scheme set"
        case .shortcut: return hasShortcut ? "Shortcut" : "No Shortcut set"
        case .auto:
            if hasScheme && hasShortcut { return "URL scheme, Shortcut as fallback" }
            if hasScheme { return "URL scheme" }
            if hasShortcut { return "Shortcut" }
            return "Nothing set yet, press Y to edit"
        }
    }

    static let seed: [Game] = [
        Game(name: "Genshin Impact", genre: "Open-world RPG", colorHex: "4A74E0", symbol: "sparkles",
             uriScheme: "genshin://", bundleID: "com.miHoYo.GenshinImpact", shortcutName: "Genshin Impact"),
        Game(name: "Hollow Knight", genre: "Metroidvania", colorHex: "586178", symbol: "moon.stars.fill",
             shortcutName: "Hollow Knight"),
        Game(name: "Teamfight Tactics", genre: "Auto battler", colorHex: "C58A2C", symbol: "crown.fill",
             shortcutName: "Teamfight Tactics"),
        Game(name: "Balatro", genre: "Roguelike deckbuilder", colorHex: "C44741", symbol: "suit.spade.fill",
             shortcutName: "Balatro"),
    ]
}

struct AppSettings: Codable, Equatable {
    var accent: Int = 0
    var tileSize: Int = 1
    var showStats: Bool = true
    var haptics: Bool = true
    var startOnLast: Bool = false
    var sgdbKey: String = ""
    var dimOnExternal: Bool = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accent = try c.decodeIfPresent(Int.self, forKey: .accent) ?? 0
        tileSize = try c.decodeIfPresent(Int.self, forKey: .tileSize) ?? 1
        showStats = try c.decodeIfPresent(Bool.self, forKey: .showStats) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
        startOnLast = try c.decodeIfPresent(Bool.self, forKey: .startOnLast) ?? false
        sgdbKey = try c.decodeIfPresent(String.self, forKey: .sgdbKey) ?? ""
        dimOnExternal = try c.decodeIfPresent(Bool.self, forKey: .dimOnExternal) ?? true
    }
}

struct Persisted: Codable {
    var games: [Game]
    var settings: AppSettings
}

struct EditTarget: Identifiable {
    let id = UUID()
    var game: Game
    var isNew: Bool
}

struct Toast: Equatable {
    var title: String
    var subtitle: String
    var symbol: String
    var colorHex: String
}

struct CatalogEntry: Identifiable, Hashable {
    var id: String { bundleID.isEmpty ? name : bundleID }
    let name: String
    let bundleID: String
    let iconURL: String?
    let schemes: [String]

    func makeGame() -> Game {
        Game(name: name, genre: "", colorHex: Theme.colorHex(for: name), symbol: "gamecontroller.fill",
             iconURL: iconURL, uriScheme: schemes.first ?? "", altSchemes: Array(schemes.dropFirst()),
             bundleID: bundleID, shortcutName: name, method: .auto)
    }
}

extension CatalogEntry: Decodable {
    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        func str(_ k: String) -> String? {
            guard let key = Key(stringValue: k) else { return nil }
            return try? c.decodeIfPresent(String.self, forKey: key)
        }
        name = (str("name") ?? "").trimmingCharacters(in: .whitespaces)
        bundleID = str("bundleID") ?? ""
        iconURL = str("iconURL")
        var list: [(Int, String)] = []
        for key in c.allKeys where key.stringValue.hasPrefix("uriScheme") {
            guard let v = str(key.stringValue)?.trimmingCharacters(in: .whitespaces), !v.isEmpty else { continue }
            let suffix = key.stringValue.dropFirst("uriScheme".count)
            let order = suffix.isEmpty ? 0 : (Int(suffix.replacingOccurrences(of: "Alt", with: "")) ?? 99)
            list.append((order, v))
        }
        schemes = list.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}

enum PadInput { case up, down, left, right, a, b, x, y, lb, rb, start }
