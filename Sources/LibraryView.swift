import SwiftUI

struct LibraryCell: View {
    @EnvironmentObject var app: AppModel
    let title: String
    let subtitle: String
    let symbol: String
    let iconURL: String?
    let colorHex: String
    let chip: String
    let chipOn: Bool
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Color(hex: colorHex)
                GameIcon(symbol: symbol, iconURL: iconURL, size: 38)
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.muted).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(chip)
                .font(.system(size: 11))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .foregroundStyle(chipOn ? Color(hex: "8FE0A8") : Color(hex: "C6C6D0"))
                .background(chipOn ? Color(hex: "16301F") : Theme.chip, in: Capsule())
        }
        .padding(10)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(selected ? app.accent : .clear, lineWidth: 2))
    }
}

struct LibraryView: View {
    @EnvironmentObject var app: AppModel
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: AppModel.columns)

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                modeChip("Catalog", .catalog)
                modeChip("My games", .mine)
                if app.libraryMode == .catalog && !app.storeStatus.isEmpty {
                    Text(app.storeStatus).font(.system(size: 11)).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer()
                if app.libraryMode == .catalog {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        TextField(app.searching ? "Searching the App Store…" : "Search the App Store", text: $app.query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .frame(width: 220)
                    .background(Theme.card, in: Capsule())
                }
            }
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: cols, spacing: 8) {
                        if app.libraryMode == .catalog {
                            ForEach(Array(app.filteredCatalog.enumerated()), id: \.element.id) { i, e in
                                let added = app.isAdded(e)
                                LibraryCell(title: e.name,
                                        subtitle: e.schemes.first ?? "No URL scheme, uses a Shortcut",
                                        symbol: "gamecontroller.fill", iconURL: e.iconURL,
                                        colorHex: Theme.colorHex(for: e.name),
                                        chip: added ? "Added" : "Add", chipOn: added,
                                        selected: i == app.libIndex)
                                    .id(i)
                                    .onTapGesture { app.libIndex = i; app.activateLibrary() }
                            }
                        } else {
                            ForEach(Array(app.games.enumerated()), id: \.element.id) { i, g in
                                LibraryCell(title: g.name, subtitle: g.methodSummary,
                                        symbol: g.symbol, iconURL: g.iconURL, colorHex: g.colorHex,
                                        chip: "Edit", chipOn: false, selected: i == app.libIndex)
                                    .id(i)
                                    .onTapGesture { app.libIndex = i; app.activateLibrary() }
                                    .contextMenu {
                                        Button { app.editing = EditTarget(game: g, isNew: false) } label: { Label("Edit", systemImage: "pencil") }
                                        Button(role: .destructive) { app.delete(g) } label: { Label("Remove", systemImage: "trash") }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .id(app.libraryMode)
                }
                .onChange(of: app.libIndex) { _, new in
                    withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
        .onChange(of: app.query) { _, _ in
            app.libIndex = 0
            app.scheduleStoreSearch()
        }
        .padding(.bottom, 4)
    }

    private func modeChip(_ title: String, _ mode: AppModel.LibraryMode) -> some View {
        let on = app.libraryMode == mode
        return Button {
            app.libraryMode = mode
            app.libIndex = 0
        } label: {
            Text(title)
                .font(.system(size: 13, weight: on ? .medium : .regular))
                .foregroundStyle(on ? .white : Theme.muted)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(on ? Color.white.opacity(0.1) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @EnvironmentObject var app: AppModel
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(Array(app.settingRows.enumerated()), id: \.offset) { i, row in
                    HStack(spacing: 10) {
                        Image(systemName: row.symbol)
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 26)
                        Text(row.title).font(.system(size: 14))
                        Spacer(minLength: 4)
                        Text(row.value)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "C6C6D0"))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.chip, in: Capsule())
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(i == app.settingsIndex ? app.accent : .clear, lineWidth: 2))
                    .onTapGesture { app.settingsIndex = i; app.changeSetting(1) }
                }
            }
            Text("Scheme data: Semmelstulle/ios-uri-schemes (CC BY 4.0). Game art: SteamGridDB.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)
            Spacer()
        }
        .padding(.bottom, 4)
    }
}
