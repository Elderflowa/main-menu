import SwiftUI

struct GameIcon: View {
    let symbol: String
    let iconURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let s = iconURL, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() } else { fallback }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            Color.white.opacity(0.18)
            Image(systemName: symbol).font(.system(size: size * 0.5)).foregroundStyle(.white)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppModel

    private var caption: String {
        guard let g = app.selectedGame else { return "Open the Library to pick one." }
        var parts: [String] = []
        if !g.genre.isEmpty { parts.append(g.genre) }
        parts.append(g.methodSummary)
        if app.settings.showStats && g.launches > 0 { parts.append("Launched \(g.launches)x") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(app.games.enumerated()), id: \.element.id) { i, game in
                            GameTile(game: game, selected: i == app.homeIndex, width: app.tileWidth)
                                .id(i)
                                .onTapGesture { app.homeIndex = i; app.launch(game) }
                                .contextMenu {
                                    Button { app.launch(game) } label: { Label("Launch", systemImage: "play.fill") }
                                    Button { app.editing = EditTarget(game: game, isNew: false) } label: { Label("Edit", systemImage: "pencil") }
                                    Button(role: .destructive) { app.delete(game) } label: { Label("Remove", systemImage: "trash") }
                                }
                        }
                        AddTile(selected: app.homeIndex == app.games.count, width: app.tileWidth)
                            .id(app.games.count)
                            .onTapGesture { app.tab = .library }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .scrollClipDisabled()
                .onChange(of: app.homeIndex) { _, new in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
            .frame(height: app.tileWidth * 1.4 + 40)
            VStack(spacing: 4) {
                Text(app.selectedGame?.name ?? "Add a game")
                    .font(.system(size: 22, weight: .medium))
                    .lineLimit(1)
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            Spacer(minLength: 0)
        }
    }
}

struct GameTile: View {
    @EnvironmentObject var app: AppModel
    let game: Game
    let selected: Bool
    let width: CGFloat

    var body: some View {
        ZStack {
            Color(hex: game.colorHex)
            if let s = game.artURL, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() } else { fallback }
                }
            } else {
                fallback
            }
        }
        .foregroundStyle(.white)
        .frame(width: width, height: width * 1.4)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(selected ? app.accent : .clear, lineWidth: 3))
        .scaleEffect(selected ? 1.07 : 1)
        .animation(.easeOut(duration: 0.12), value: selected)
    }

    private var fallback: some View {
        VStack(spacing: 8) {
            GameIcon(symbol: game.symbol, iconURL: game.iconURL, size: width * 0.55)
            Text(game.name)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)
        }
    }
}

struct AddTile: View {
    @EnvironmentObject var app: AppModel
    let selected: Bool
    let width: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus").font(.system(size: 28))
            Text("Add game").font(.system(size: 12))
        }
        .foregroundStyle(Theme.muted)
        .frame(width: width, height: width * 1.4)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(selected ? app.accent : .clear, lineWidth: 3))
        .scaleEffect(selected ? 1.07 : 1)
        .animation(.easeOut(duration: 0.12), value: selected)
    }
}
