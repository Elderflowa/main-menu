import GameController

final class PadMonitor {
    private let onInput: (PadInput) -> Void
    private let onStatus: (String?, Int?) -> Void

    init(onInput: @escaping (PadInput) -> Void, onStatus: @escaping (String?, Int?) -> Void) {
        self.onInput = onInput
        self.onStatus = onStatus
        let nc = NotificationCenter.default
        nc.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
            if let c = note.object as? GCController { self?.attach(c) }
            self?.report()
        }
        nc.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.report()
        }
        GCController.controllers().forEach { attach($0) }
        report()
    }

    private func report() {
        let c = GCController.controllers().first
        let name = c.map { $0.productCategory.isEmpty ? ($0.vendorName ?? "Controller") : $0.productCategory }
        let battery = c?.battery.map { Int($0.batteryLevel * 100) }
        onStatus(name, battery)
    }

    private func bind(_ button: GCControllerButtonInput, _ input: PadInput) {
        button.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onInput(input) }
        }
    }

    private func attach(_ controller: GCController) {
        guard let pad = controller.extendedGamepad else { return }
        bind(pad.dpad.up, .up); bind(pad.dpad.down, .down)
        bind(pad.dpad.left, .left); bind(pad.dpad.right, .right)
        bind(pad.leftThumbstick.up, .up); bind(pad.leftThumbstick.down, .down)
        bind(pad.leftThumbstick.left, .left); bind(pad.leftThumbstick.right, .right)
        bind(pad.buttonA, .a); bind(pad.buttonB, .b)
        bind(pad.buttonX, .x); bind(pad.buttonY, .y)
        bind(pad.leftShoulder, .lb); bind(pad.rightShoulder, .rb)
        bind(pad.buttonMenu, .start)
    }
}
