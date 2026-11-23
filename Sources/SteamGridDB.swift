import Foundation

enum SteamGridDB {
    static let base = "https://www.steamgriddb.com/api/v2"

    private struct Envelope<T: Decodable>: Decodable { let data: T? }
    struct Match: Decodable, Identifiable { let id: Int; let name: String }
    struct Art: Decodable { let url: String; let thumb: String? }

    private static func get<T: Decodable>(_ path: String, key: String, as type: T.Type) async -> T? {
        guard let url = URL(string: base + path) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return (try? JSONDecoder().decode(Envelope<T>.self, from: data))?.data
    }

    static func search(_ name: String, key: String) async -> [Match] {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        guard let term = name.addingPercentEncoding(withAllowedCharacters: allowed) else { return [] }
        return await get("/search/autocomplete/\(term)", key: key, as: [Match].self) ?? []
    }

    static func grids(gameID: Int, key: String) async -> [Art] {
        let filters = "types=static&nsfw=false&humor=false"
        var list = await get("/grids/game/\(gameID)?dimensions=600x900&\(filters)", key: key, as: [Art].self) ?? []
        if list.isEmpty {
            list = await get("/grids/game/\(gameID)?\(filters)", key: key, as: [Art].self) ?? []
        }
        return list
    }

    /// Returns a vertical poster URL and a square icon URL for the best match of `name`.
    static func art(for name: String, key: String) async -> (poster: String?, icon: String?)? {
        guard let game = await search(name, key: key).first else { return nil }
        let grids = await grids(gameID: game.id, key: key)
        let icons = await get("/icons/game/\(game.id)?types=static&nsfw=false&humor=false", key: key, as: [Art].self) ?? []
        return (grids.first?.url, icons.first?.url)
    }
}
