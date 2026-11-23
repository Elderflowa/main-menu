import SwiftUI

struct ArtPicker: View {
    @EnvironmentObject var app: AppModel
    @Binding var selected: String?
    @State var term: String
    @State private var matches: [SteamGridDB.Match] = []
    @State private var images: [SteamGridDB.Art] = []
    @State private var loading = false
    @State private var activeID: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TextField("Game title on SteamGridDB", text: $term)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    Button("Search") { Task { await search() } }
                }
                if matches.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(matches.prefix(8)) { m in
                                Button(m.name) { Task { await load(m.id) } }
                                    .buttonStyle(.bordered)
                                    .tint(m.id == activeID ? .accentColor : .gray)
                            }
                        }
                    }
                }
                if loading { ProgressView() }
                if !loading && images.isEmpty {
                    Text("No art found. Try another title.").font(.footnote).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(images, id: \.url) { img in
                        AsyncImage(url: URL(string: img.thumb ?? img.url)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.25)
                            }
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: selected == img.url ? 3 : 0))
                        .onTapGesture { selected = img.url }
                    }
                }
                if selected != nil {
                    Button("Use automatic art", role: .destructive) { selected = nil }
                }
            }
            .padding()
        }
        .navigationTitle("Choose art")
        .navigationBarTitleDisplayMode(.inline)
        .task { await search() }
    }

    private func search() async {
        let key = app.settings.sgdbKey
        let q = term.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !q.isEmpty else { return }
        loading = true
        matches = await SteamGridDB.search(q, key: key)
        if let first = matches.first {
            await load(first.id)
        } else {
            images = []
            loading = false
        }
    }

    private func load(_ id: Int) async {
        loading = true
        activeID = id
        images = await SteamGridDB.grids(gameID: id, key: app.settings.sgdbKey)
        loading = false
    }
}
