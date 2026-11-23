import SwiftUI

struct GameEditor: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Game
    @State private var alts: String
    @State private var testResult: String?
    private let isNew: Bool

    init(target: EditTarget) {
        _draft = State(initialValue: target.game)
        _alts = State(initialValue: target.game.altSchemes.joined(separator: ", "))
        isNew = target.isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Name", text: $draft.name)
                    TextField("Genre", text: $draft.genre)
                }
                Section("Launch") {
                    Picker("Method", selection: $draft.method) {
                        ForEach(LaunchMethod.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("URL scheme, for example genshin://", text: $draft.uriScheme)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Alternative schemes, comma separated", text: $alts)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Shortcut name", text: $draft.shortcutName)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Create this Shortcut in the Shortcuts app") {
                        if let url = URL(string: "shortcuts://create-shortcut") { UIApplication.shared.open(url) }
                    }
                    Text("A Shortcut is only needed when the game has no URL scheme. In Shortcuts add the action Open App, pick the game, and name the Shortcut exactly like the name above.")
                        .font(.footnote).foregroundStyle(.secondary)
                    TextField("Bundle ID (reference only)", text: $draft.bundleID)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Test launch") {
                        var g = draft
                        g.altSchemes = parsedAlts
                        Task {
                            let via = await Launcher.launch(g)
                            testResult = via.map { "Opened via \($0)" } ?? "Nothing opened. Check the scheme or Shortcut name."
                        }
                    }
                    if let r = testResult { Text(r).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("Look") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Theme.swatches, id: \.self) { hex in
                                Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: draft.colorHex == hex ? 3 : 0))
                                    .onTapGesture { draft.colorHex = hex }
                            }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Theme.symbols, id: \.self) { s in
                                Image(systemName: s).font(.system(size: 20))
                                    .frame(width: 36, height: 36)
                                    .background(draft.symbol == s ? Color.white.opacity(0.15) : .clear, in: Circle())
                                    .onTapGesture { draft.symbol = s }
                            }
                        }
                    }
                }
                Section("Art") {
                    if app.settings.sgdbKey.isEmpty {
                        Text("Add a SteamGridDB key in Settings to pick game art.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        NavigationLink {
                            ArtPicker(selected: $draft.artURL, term: draft.name)
                        } label: {
                            HStack {
                                Text("Choose game art")
                                Spacer()
                                if let s = draft.artURL, let url = URL(string: s) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image { image.resizable().scaledToFill() } else { Color.gray.opacity(0.3) }
                                    }
                                    .frame(width: 30, height: 42)
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                }
                            }
                        }
                    }
                }
                if !isNew {
                    Section {
                        Button("Remove from Main Menu", role: .destructive) {
                            app.delete(draft)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New game" : "Edit game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.altSchemes = parsedAlts
                        if draft.colorHex.isEmpty { draft.colorHex = Theme.colorHex(for: draft.name) }
                        app.commit(draft, isNew: isNew)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var parsedAlts: [String] {
        alts.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
