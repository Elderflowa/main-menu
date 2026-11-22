import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    enum Tab: Int, CaseIterable {
        case home, library, settings
        var title: String { ["Home", "Library", "Settings"][rawValue] }
        var symbol: String { ["house.fill", "books.vertical.fill", "gearshape.fill"][rawValue] }
    }
    enum LibraryMode { case catalog, mine }

    static let columns = 3
    static let settingsCount = 6
    static let catalogURL = URL(string: "https://raw.githubusercontent.com/Semmelstulle/ios-uri-schemes/main/game_list.json")!

    @Published var tab: Tab = .home
    @Published var games: [Game] = []
    @Published var settings = AppSettings() { didSet { save() } }
    @Published var homeIndex = 0
    @Published var libraryMode: LibraryMode = .catalog
    @Published var libIndex = 0
    @Published var settingsIndex = 0
    @Published var query = ""
    @Published var catalog: [CatalogEntry] = []
    @Published var catalogStatus = "Bundled list"
    @Published var editing: EditTarget?
    @Published var toast: Toast?
    @Published var controllerName: String?
    @Published var controllerBattery: Int?

    private var pad: PadMonitor?
    private var toastTask: Task<Void, Never>?

    init() {
        load()
        loadCatalog()
        if settings.startOnLast,
           let i = games.indices.max(by: { (games[$0].lastPlayed ?? .distantPast) < (games[$1].lastPlayed ?? .distantPast) }),
           games[i].lastPlayed != nil {
            homeIndex = i
        }
        pad = PadMonitor(
            onInput: { [weak self] input in
                Task { @MainActor in self?.handle(input) }
            },
            onStatus: { [weak self] name, battery in
                Task { @MainActor in
                    self?.controllerName = name
                    self?.controllerBattery = battery
                }
            })
    }

    // MARK: Derived

    var accent: Color { Color(hex: Theme.accents[min(settings.accent, Theme.accents.count - 1)]) }
    var tileWidth: CGFloat { [96, 120, 144][min(settings.tileSize, 2)] }

    var selectedGame: Game? {
        games.indices.contains(homeIndex) ? games[homeIndex] : nil
    }

    var filteredCatalog: [CatalogEntry] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return catalog }
        return catalog.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.bundleID.localizedCaseInsensitiveContains(q) }
    }

    var libraryCount: Int { libraryMode == .catalog ? filteredCatalog.count : games.count }

    func isAdded(_ e: CatalogEntry) -> Bool {
        games.contains { (!$0.bundleID.isEmpty && $0.bundleID == e.bundleID) || $0.name == e.name }
    }

    var settingRows: [(title: String, value: String, symbol: String)] {
        [("Accent color", Theme.accentNames[settings.accent], "paintpalette.fill"),
         ("Tile size", ["Small", "Medium", "Large"][settings.tileSize], "square.grid.2x2.fill"),
         ("Show launch stats", settings.showStats ? "On" : "Off", "clock.fill"),
         ("Haptic ticks", settings.haptics ? "On" : "Off", "iphone.radiowaves.left.and.right"),
         ("Start on last played", settings.startOnLast ? "On" : "Off", "play.circle.fill"),
         ("Refresh scheme list", catalogStatus, "arrow.clockwise")]
    }

    // MARK: Input

    func handle(_ input: PadInput) {
        if editing != nil {
            if input == .b { editing = nil }
            return
        }
        switch input {
        case .lb: cycleTab(-1); return
        case .rb: cycleTab(1); return
        case .b, .start:
            tab = .home
            return
        default: break
        }
        switch tab {
        case .home: homeInput(input)
        case .library: libraryInput(input)
        case .settings: settingsInput(input)
        }
    }

    private func tick() {
        guard settings.haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func cycleTab(_ d: Int) {
        let n = Tab.allCases.count
        tab = Tab(rawValue: (tab.rawValue + d + n) % n) ?? .home
        tick()
    }

    private func homeInput(_ i: PadInput) {
        switch i {
        case .left: if homeIndex > 0 { homeIndex -= 1; tick() }
        case .right: if homeIndex < games.count { homeIndex += 1; tick() }
        case .a:
            if let g = selectedGame { launch(g) } else { tab = .library }
        case .y:
            if let g = selectedGame { editing = EditTarget(game: g, isNew: false) }
        case .x:
            tab = .library
        default: break
        }
    }

    private func libraryInput(_ i: PadInput) {
        let n = libraryCount
        let c = Self.columns
        switch i {
        case .left: if libIndex % c > 0 { libIndex -= 1; tick() }
        case .right: if libIndex % c < c - 1 && libIndex < n - 1 { libIndex += 1; tick() }
        case .up: if libIndex - c >= 0 { libIndex -= c; tick() }
        case .down: if libIndex + c < n { libIndex += c; tick() }
        case .a: activateLibrary()
        case .x:
            libraryMode = libraryMode == .catalog ? .mine : .catalog
            libIndex = 0
        case .y: editing = EditTarget(game: Game(name: ""), isNew: true)
        default: break
        }
    }

    func activateLibrary() {
        guard libIndex >= 0 else { return }
        if libraryMode == .catalog {
            let list = filteredCatalog
            guard list.indices.contains(libIndex) else { return }
            let entry = list[libIndex]
            if let existing = games.firstIndex(where: { ($0.bundleID == entry.bundleID && !entry.bundleID.isEmpty) || $0.name == entry.name }) {
                games.remove(at: existing)
            } else {
                games.append(entry.makeGame())
            }
            save()
        } else if games.indices.contains(libIndex) {
            editing = EditTarget(game: games[libIndex], isNew: false)
        }
        tick()
    }

    private func settingsInput(_ i: PadInput) {
        switch i {
        case .up: if settingsIndex > 0 { settingsIndex -= 1; tick() }
        case .down: if settingsIndex < Self.settingsCount - 1 { settingsIndex += 1; tick() }
        case .a, .right: changeSetting(1)
        case .left: changeSetting(-1)
        default: break
        }
    }

    func changeSetting(_ d: Int) {
        switch settingsIndex {
        case 0: settings.accent = (settings.accent + d + Theme.accents.count) % Theme.accents.count
        case 1: settings.tileSize = (settings.tileSize + d + 3) % 3
        case 2: settings.showStats.toggle()
        case 3: settings.haptics.toggle()
        case 4: settings.startOnLast.toggle()
        default: Task { await refreshCatalog() }
        }
        tick()
    }

    // MARK: Games

    func commit(_ game: Game, isNew: Bool) {
        if isNew {
            games.append(game)
            homeIndex = games.count - 1
        } else if let i = games.firstIndex(where: { $0.id == game.id }) {
            games[i] = game
        }
        save()
    }

    func delete(_ game: Game) {
        games.removeAll { $0.id == game.id }
        homeIndex = min(homeIndex, games.count)
        libIndex = max(0, min(libIndex, libraryCount - 1))
        save()
    }

    func launch(_ game: Game) {
        showToast(Toast(title: game.name, subtitle: "Opening…", symbol: game.symbol, colorHex: game.colorHex), seconds: 1.6)
        Task {
            let via = await Launcher.launch(game)
            if via != nil {
                if let i = games.firstIndex(where: { $0.id == game.id }) {
                    games[i].lastPlayed = Date()
                    games[i].launches += 1
                    save()
                }
            } else {
                showToast(Toast(title: "Couldn't open \(game.name)",
                                subtitle: "Check the URL scheme or Shortcut name. Press Y to edit.",
                                symbol: "exclamationmark.triangle.fill", colorHex: "8A2F2F"), seconds: 3)
            }
        }
    }

    private func showToast(_ t: Toast, seconds: Double) {
        toastTask?.cancel()
        toast = t
        toastTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !Task.isCancelled { toast = nil }
        }
    }

    // MARK: Persistence

    private static var supportDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private var stateURL: URL { Self.supportDir.appendingPathComponent("deck.json") }
    private var catalogCacheURL: URL { Self.supportDir.appendingPathComponent("game_list.json") }

    private func load() {
        if let data = try? Data(contentsOf: stateURL),
           let p = try? JSONDecoder().decode(Persisted.self, from: data) {
            games = p.games
            settings = p.settings
        } else {
            games = Game.seed
        }
    }

    func save() {
        let p = Persisted(games: games, settings: settings)
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }

    // MARK: Catalog

    private static func decode(_ data: Data) -> [CatalogEntry] {
        let list = (try? JSONDecoder().decode([CatalogEntry].self, from: data)) ?? []
        return list.filter { !$0.name.isEmpty }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func loadCatalog() {
        if let data = try? Data(contentsOf: catalogCacheURL) {
            let list = Self.decode(data)
            if !list.isEmpty { catalog = list; catalogStatus = "Cached list"; return }
        }
        if let url = Bundle.main.url(forResource: "game_list", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            catalog = Self.decode(data)
        }
    }

    func refreshCatalog() async {
        catalogStatus = "Updating…"
        do {
            let (data, response) = try await URLSession.shared.data(from: Self.catalogURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let list = Self.decode(data)
            guard !list.isEmpty else { throw URLError(.cannotParseResponse) }
            try data.write(to: catalogCacheURL, options: .atomic)
            catalog = list
            catalogStatus = "Updated, \(list.count) apps"
        } catch {
            catalogStatus = "Update failed"
        }
    }
}
