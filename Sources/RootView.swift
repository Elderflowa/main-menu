import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            HStack(spacing: 0) {
                Rail()
                VStack(spacing: 0) {
                    TopBar()
                    Group {
                        switch app.tab {
                        case .home: HomeView()
                        case .library: LibraryView()
                        case .settings: SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    HintBar()
                }
                .padding(.trailing, 4)
            }
            if let t = app.toast {
                ToastView(toast: t)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: app.toast)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .alert("SteamGridDB API key", isPresented: $app.keyAlert) {
            TextField("Paste your key", text: $app.keyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Save") { app.saveKey() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Get a free key at steamgriddb.com/profile/preferences/api")
        }
        .sheet(item: $app.editing) { target in
            GameEditor(target: target)
                .environmentObject(app)
                .preferredColorScheme(.dark)
        }
    }
}

struct Rail: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        VStack(spacing: 10) {
            ButtonBadge(label: "LB")
            ForEach(AppModel.Tab.allCases, id: \.self) { t in
                Button { app.tab = t } label: {
                    Image(systemName: t.symbol)
                        .font(.system(size: 22))
                        .frame(width: 46, height: 46)
                        .foregroundStyle(app.tab == t ? Color.white : Theme.muted)
                        .background(app.tab == t ? Color.white.opacity(0.1) : .clear,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            ButtonBadge(label: "RB")
        }
        .frame(width: 64)
        .frame(maxHeight: .infinity)
    }
}

struct TopBar: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        HStack {
            Text(app.tab.title).font(.system(size: 17, weight: .medium))
            Spacer()
            if let name = app.controllerName {
                HStack(spacing: 5) {
                    Image(systemName: "gamecontroller.fill")
                    Text(app.controllerBattery.map { "\(name) · \($0)%" } ?? name)
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "9BD8B0"))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color(hex: "15241B"), in: Capsule())
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "gamecontroller")
                    Text("No controller")
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Theme.chip, in: Capsule())
            }
            Text(Date(), style: .time)
                .font(.system(size: 13, weight: .medium))
                .padding(.leading, 8)
        }
        .padding(.top, 8)
        .frame(height: 40)
    }
}

struct ButtonBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: label.count > 1 ? 10 : 11, weight: .semibold))
            .foregroundStyle(label.count > 1 ? Theme.muted : .white)
            .padding(.horizontal, label.count > 1 ? 6 : 0)
            .frame(minWidth: 20, minHeight: 20)
            .background(Theme.chip, in: Capsule())
    }
}

struct HintBar: View {
    @EnvironmentObject var app: AppModel

    private var hints: [(String, String)] {
        switch app.tab {
        case .home: return [("A", "Launch"), ("Y", "Edit"), ("X", "Library")]
        case .library:
            return app.libraryMode == .catalog
                ? [("A", "Add or remove"), ("X", "My games"), ("Y", "New game")]
                : [("A", "Edit"), ("X", "Catalog"), ("Y", "New game")]
        case .settings: return [("A", "Change"), ("B", "Home")]
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            ForEach(hints, id: \.0) { h in
                HStack(spacing: 5) {
                    ButtonBadge(label: h.0)
                    Text(h.1)
                }
            }
            HStack(spacing: 5) {
                ButtonBadge(label: "LB"); ButtonBadge(label: "RB")
                Text("Tabs")
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.muted)
        .frame(height: 40)
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        ZStack {
            Color(hex: toast.colorHex).ignoresSafeArea()
            VStack(spacing: 8) {
                Image(systemName: toast.symbol).font(.system(size: 56))
                Text(toast.title).font(.system(size: 24, weight: .medium))
                Text(toast.subtitle).font(.system(size: 13)).opacity(0.8)
            }
            .multilineTextAlignment(.center)
            .padding(30)
        }
    }
}
