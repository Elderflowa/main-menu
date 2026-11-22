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

    var body: some View {
        HStack(spacing: 18) {
            InfoPanel(game: app.selectedGame)
                .frame(width: 250)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(Array(app.games.enumerated()), id: \.element.id) { i, game in
                            GameTile(game: game, selected: i == app.homeIndex, width: app.tileWidth)
                                .id(i)
                                .onTapGesture {
                                    if app.homeIndex == i { app.launch(game) } else { app.homeIndex = i }
                                }
                        }
                        AddTile(selected: app.homeIndex == app.games.count, width: app.tileWidth)
                            .id(app.games.count)
                            .onTapGesture { app.tab = .library }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
                .onChange(of: app.homeIndex) { _, new in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
        .padding(.bottom, 4)
    }
}

struct InfoPanel: View {
    @EnvironmentObject var app: AppModel
    let game: Game?

    var body: some View {
        let hex = game?.colorHex ?? "25252B"
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(hex: hex))
            Image(systemName: game?.symbol ?? "plus")
                .font(.system(size: 110))
                .foregroundStyle(.white.opacity(0.22))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)
            VStack(alignment: .leading, spacing: 4) {
                if let g = game {
                    if !g.genre.isEmpty { Text(g.genre).font(.system(size: 12)).opacity(0.85) }
                    Text(g.name).font(.system(size: 26, weight: .medium)).lineLimit(2).minimumScaleFactor(0.7)
                    if app.settings.showStats {
                        Text(g.launches == 0 ? "Not launched yet" : "Launched \(g.launches) time\(g.launches == 1 ? "" : "s")")
                            .font(.system(size: 12)).opacity(0.85)
                    }
                    Button { app.launch(g) } label: {
                        Label("Launch", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                    Text("Via \(g.methodSummary)").font(.system(size: 11)).opacity(0.8)
                } else {
                    Text("Add a game").font(.system(size: 22, weight: .medium))
                    Text("Open the Library to pick one.").font(.system(size: 12)).opacity(0.8)
                }
            }
            .foregroundStyle(.white)
            .padding(18)
        }
    }
}

struct GameTile: View {
    @EnvironmentObject var app: AppModel
    let game: Game
    let selected: Bool
    let width: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            GameIcon(symbol: game.symbol, iconURL: game.iconURL, size: width * 0.55)
            Text(game.name)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)
        }
        .foregroundStyle(.white)
        .frame(width: width, height: width * 1.4)
        .background(Color(hex: game.colorHex), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(selected ? app.accent : .clear, lineWidth: 3))
        .scaleEffect(selected ? 1.07 : 1)
        .animation(.easeOut(duration: 0.12), value: selected)
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
