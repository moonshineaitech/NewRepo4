import StoreKit
import SwiftUI

/// The boutique: where one ascends. A single non-consumable purchase
/// re-finishes the instrument in 24-karat gold.
struct EliteBoutiqueView: View {

    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ObsidianBackground()

            ScrollView {
                VStack(spacing: 0) {
                    crown
                        .padding(.top, 46)

                    Text("GONG ÉLITE")
                        .font(.system(size: 34, weight: .thin, design: .serif))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldMid]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.top, 22)

                    Text("The instrument, re-imagined in twenty-four karats.")
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.inscription)
                        .padding(.top, 8)

                    divider
                        .padding(.vertical, 28)

                    VStack(spacing: 22) {
                        featureRow(
                            icon: "sparkles",
                            title: "24-Karat Finish",
                            detail: "The disc, the boss, and the rim are re-struck in radiant gold."
                        )
                        featureRow(
                            icon: "waveform",
                            title: "The Aurum Voice",
                            detail: "A brighter, rarer resonance, tuned for the very few."
                        )
                        featureRow(
                            icon: "sun.max.fill",
                            title: "Golden Radiance",
                            detail: "Strike bursts, aura, and ripples turn white-gold."
                        )
                        featureRow(
                            icon: "laurel.leading",
                            title: "The Crest",
                            detail: "Your instrument bears the Élite mark. Forever."
                        )
                    }
                    .padding(.horizontal, 36)

                    divider
                        .padding(.vertical, 28)

                    purchaseSection
                        .padding(.horizontal, 32)

                    if let error = store.lastError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.top, 14)
                            .padding(.horizontal, 32)
                    }

                    Text("One-time purchase. Yours forever, across your devices.")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Theme.inscription.opacity(0.8))
                        .padding(.top, 22)
                        .padding(.bottom, 42)
                }
                .frame(maxWidth: .infinity)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inscription)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 18)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pieces

    private var crown: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 44))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldLight, Theme.goldDark]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Theme.goldMid.opacity(0.7), radius: 22)
    }

    private var divider: some View {
        HStack(spacing: 12) {
            line
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.goldMid.opacity(0.7))
            line
        }
        .padding(.horizontal, 60)
    }

    private var line: some View {
        LinearGradient(
            gradient: Gradient(colors: [.clear, Theme.goldMid.opacity(0.5), .clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Theme.goldLight)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.parchment)
                Text(detail)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Theme.inscription)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if store.isElite {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.goldLight)
                Text("You are Élite.")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundStyle(Theme.goldHighlight)
                Text("The Aurum voice answers only to you.")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Theme.inscription)
            }
        } else {
            VStack(spacing: 16) {
                Button {
                    Task { await store.purchaseElite() }
                } label: {
                    HStack(spacing: 10) {
                        if store.purchaseInFlight {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("BECOME ÉLITE")
                                .tracking(2.5)
                            Text("·")
                            Text(store.eliteProduct?.displayPrice ?? "$999.99")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.02))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldLight, Theme.goldMid]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .shadow(color: Theme.goldMid.opacity(0.5), radius: 16, y: 6)
                }
                .disabled(store.purchaseInFlight)

                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Theme.inscription)
                        .underline()
                }
            }
        }
    }
}

#Preview {
    EliteBoutiqueView()
        .environmentObject(StoreManager())
}
