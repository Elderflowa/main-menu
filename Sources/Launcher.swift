import UIKit

enum Launcher {
    /// One Shortcut the user creates once. It receives an app name as text and runs Open App with it.
    static let universalShortcut = "Main Menu Launch"

    private static func normalized(_ scheme: String) -> URL? {
        let s = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        return URL(string: s.contains("://") ? s : s + "://")
    }

    @MainActor
    private static func open(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url, options: [:])
    }

    /// Returns a short description of what worked, or nil if nothing opened.
    @MainActor
    static func launch(_ game: Game) async -> String? {
        let schemes = ([game.uriScheme] + game.altSchemes).compactMap(normalized)
        let shortcut = game.shortcutName.trimmingCharacters(in: .whitespacesAndNewlines)

        if game.method != .shortcut {
            for url in schemes {
                if await open(url) { return url.absoluteString }
            }
        }
        if game.method != .urlScheme, !shortcut.isEmpty {
            var comps = URLComponents()
            comps.scheme = "shortcuts"
            comps.host = "run-shortcut"
            comps.queryItems = [
                URLQueryItem(name: "name", value: universalShortcut),
                URLQueryItem(name: "input", value: "text"),
                URLQueryItem(name: "text", value: shortcut),
            ]
            if let url = comps.url, await open(url) {
                return "Shortcut for \(shortcut)"
            }
        }
        return nil
    }
}
