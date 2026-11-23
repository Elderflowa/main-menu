import SwiftUI
import UIKit

/// Shows Main Menu full screen on a connected monitor or AirPlay display.
final class ExternalSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let model = AppModel.shared
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ExternalRoot().environmentObject(model))
        window.isHidden = false
        self.window = window
        model.externalConnected = true
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        window = nil
        AppModel.shared.externalConnected = false
    }
}

/// Lays the UI out on the design height (393 pt) and scales it up to fill the display.
struct ExternalRoot: View {
    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.height / 393
            MainContent()
                .frame(width: geo.size.width / scale, height: 393)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .background(Theme.bg)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
