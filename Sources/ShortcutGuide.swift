import SwiftUI

struct ShortcutGuide: View {
    @EnvironmentObject var app: AppModel

    private let steps = [
        "Easiest: install the ready-made Shortcut with A. Otherwise build it yourself:",
        "Open Shortcuts and start a new shortcut.",
        "Name it exactly Main Menu Launch.",
        "Add the action Open App. Tap its app field and choose the Shortcut Input variable.",
        "Come back and test it. The Settings app should open.",
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set up the shared Shortcut").font(.system(size: 22, weight: .medium))
                    Text("Games without a URL scheme open through this one Shortcut. You only do this once.")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, text in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 22, height: 22)
                                .background(app.accent, in: Circle())
                                .foregroundStyle(.black)
                            Text(text).font(.system(size: 14)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("Each game's App name must match the name under its icon on your Home Screen. Games with a URL scheme, like Genshin Impact, skip this.")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: 10) {
                    guideButton("A", "Install ready-made Shortcut") { app.installShortcut() }
                    guideButton("X", "Test the Shortcut") { app.testShortcut() }
                    guideButton("Y", "Open Shortcuts to build it") { app.openShortcutCreator() }
                    guideButton("B", "Close") { app.showGuide = false }
                }
                .frame(width: 210)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    private func guideButton(_ badge: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ButtonBadge(label: badge)
                Text(title).font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
