import Foundation

enum SteamGridDB {
    static let base = "https://www.steamgriddb.com/api/v2"

    private struct Envelope<T: Decodable>: Decodable { let data: T? }
    private struct SGame: Decodable { let id: Int; let name: String }
    private struct SImage: Decodable { let url: String }

    private static func get<T: Decodable>(_ path: String, key: String, as type: T.Type) async -> T? {
        guard let url = URL(string: base + path) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return (try? JSONDecoder().decode(Envelope<T>.self, from: data))?.data
    }

    /// Returns a vertical poster URL and a square icon URL for the best match of `name`.
    static func art(for name: String, key: String) async -> (poster: String?, icon: String?)? {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        guard let term = name.addingPercentEncoding(withAllowedCharacters: allowed),
              let games = await get("/search/autocomplete/\(term)", key: key, as: [SGame].self),
              let game = games.first else { return nil }
        let filters = "types=static&nsfw=false&humor=false"
        var grids = await get("/grids/game/\(game.id)?dimensions=600x900&\(filters)", key: key, as: [SImage].self) ?? []
        if grids.isEmpty {
            grids = await get("/grids/game/\(game.id)?\(filters)", key: key, as: [SImage].self) ?? []
        }
        let icons = await get("/icons/game/\(game.id)?\(filters)", key: key, as: [SImage].self) ?? []
        return (grids.first?.url, icons.first?.url)
    }
}
