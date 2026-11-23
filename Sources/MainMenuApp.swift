import SwiftUI

@main
struct MainMenuApp: App {
    @StateObject private var model = AppModel.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    model.applyPower(active: phase == .active)
                }
        }
    }
}
