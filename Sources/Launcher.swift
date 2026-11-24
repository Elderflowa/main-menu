import UIKit

enum Launcher {
    /// One Shortcut the user creates once. It receives an app name as text and runs Open App with it.
    static let universalShortcut = "Main Menu Launch"

    static let candidates = ["hollowknight", "hollow-knight", "hollowknightmobile", "teamcherry", "hollowknightsilksong", "silksong", "balatro", "playstack", "localthunk", "balatromobile", "tft", "teamfighttactics", "tftmobile", "tacticians", "riot", "riotgames", "riotmobile", "riotclient", "riotid", "lol", "leagueoflegends", "wildrift", "valorant", "lor", "legendsofruneterra", "genshin", "genshinimpact", "hoyoverse", "mihoyo", "hoyolab", "hoyoplay", "hsr", "starrail", "zzz", "netflix", "netflixgames", "unity", "unityads", "gamecenter", "gamecenter-games"]

    /// Which candidate schemes some installed app answers to. Only schemes listed in
    /// LSApplicationQueriesSchemes can be checked, so this is a guess list, not a scan.
    @MainActor
    static func probe() -> [String] {
        candidates.filter { s in
            URL(string: s + "://").map { UIApplication.shared.canOpenURL($0) } ?? false
        }.map { $0 + "://" }
    }

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
