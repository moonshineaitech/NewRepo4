import SwiftUI

/// The Gong design language: obsidian, bronze, and — for the elite — 24-karat gold.
enum Theme {

    // MARK: Field

    static let obsidian = Color(red: 0.043, green: 0.035, blue: 0.055)
    static let obsidianDeep = Color(red: 0.016, green: 0.012, blue: 0.024)
    static let ember = Color(red: 0.16, green: 0.10, blue: 0.05)

    // MARK: Bronze (standard finish)

    static let bronzeDark = Color(red: 0.23, green: 0.13, blue: 0.05)
    static let bronzeMid = Color(red: 0.52, green: 0.33, blue: 0.14)
    static let bronzeLight = Color(red: 0.78, green: 0.56, blue: 0.26)
    static let bronzeHighlight = Color(red: 0.96, green: 0.82, blue: 0.52)

    // MARK: Aurum (élite finish)

    static let goldDark = Color(red: 0.42, green: 0.28, blue: 0.06)
    static let goldMid = Color(red: 0.78, green: 0.58, blue: 0.16)
    static let goldLight = Color(red: 1.00, green: 0.84, blue: 0.38)
    static let goldHighlight = Color(red: 1.00, green: 0.96, blue: 0.78)

    static let accent = Color(red: 1.00, green: 0.84, blue: 0.35)
    static let parchment = Color(red: 0.93, green: 0.89, blue: 0.80)
    static let inscription = Color(red: 0.62, green: 0.56, blue: 0.44)

    // MARK: Finishes

    struct Finish {
        let dark: Color
        let mid: Color
        let light: Color
        let highlight: Color
        let particle: Color
        let ringGlow: Color
    }

    static let bronzeFinish = Finish(
        dark: bronzeDark,
        mid: bronzeMid,
        light: bronzeLight,
        highlight: bronzeHighlight,
        particle: Color(red: 1.0, green: 0.78, blue: 0.42),
        ringGlow: Color(red: 1.0, green: 0.72, blue: 0.34)
    )

    static let goldFinish = Finish(
        dark: goldDark,
        mid: goldMid,
        light: goldLight,
        highlight: goldHighlight,
        particle: Color(red: 1.0, green: 0.92, blue: 0.60),
        ringGlow: Color(red: 1.0, green: 0.88, blue: 0.45)
    )

    static func finish(elite: Bool) -> Finish {
        elite ? goldFinish : bronzeFinish
    }
}

/// Deterministic random source so the hammered texture is identical every launch.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Roman numerals for the resonance ledger. Values above 3999 gain repeated Ms,
/// which only makes the ledger look more imperial.
func romanNumeral(_ value: Int) -> String {
    guard value > 0 else { return "—" }
    var remainder = value
    var result = ""
    let table: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]
    for (amount, numeral) in table {
        while remainder >= amount {
            result += numeral
            remainder -= amount
        }
    }
    return result
}
