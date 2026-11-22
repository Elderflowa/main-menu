import SwiftUI

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}

enum Theme {
    static let bg = Color(hex: "0C0C10")
    static let card = Color(hex: "16161B")
    static let chip = Color(hex: "25252B")
    static let muted = Color(hex: "8D8D99")
    static let accents = ["5B8CFF", "4FD08A", "FF8A5B", "E06BD0"]
    static let accentNames = ["Blue", "Green", "Orange", "Pink"]
    static let swatches = ["4A74E0", "586178", "C58A2C", "C44741", "7A58C9", "2F8F7B", "B5563A", "5A9A3C"]
    static let symbols = ["gamecontroller.fill", "sparkles", "flame.fill", "bolt.fill", "crown.fill",
                          "suit.spade.fill", "leaf.fill", "moon.stars.fill", "shield.fill", "star.fill"]

    static func colorHex(for name: String) -> String {
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return swatches[sum % swatches.count]
    }
}
