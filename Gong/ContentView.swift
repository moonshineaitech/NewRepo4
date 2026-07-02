import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var store: StoreManager
    @StateObject private var model = GongModel()
    @AppStorage("gong.resonances") private var resonances = 0
    @State private var showEliteBoutique = false

    var body: some View {
        ZStack {
            ObsidianBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, 18)

                GongStageView(model: model, elite: store.isElite) { _ in
                    resonances += 1
                }

                footer
                    .padding(.bottom, 26)
            }

            VStack {
                HStack {
                    Spacer()
                    crownButton
                        .padding(.trailing, 22)
                        .padding(.top, 14)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showEliteBoutique) {
            EliteBoutiqueView()
                .environmentObject(store)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(spacing: 10) {
            Text("G O N G")
                .font(.system(size: 42, weight: .ultraLight, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.parchment, Theme.bronzeLight]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("ONE SOUND · INFINITE STATUS")
                .font(.system(size: 10, weight: .light))
                .tracking(3.5)
                .foregroundStyle(Theme.inscription)
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("RESONANCES")
                .font(.system(size: 9, weight: .medium))
                .tracking(3)
                .foregroundStyle(Theme.inscription)

            Text(romanNumeral(resonances))
                .font(.system(size: 26, weight: .light, design: .serif))
                .foregroundStyle(Theme.parchment)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 40)

            if store.isElite {
                Text("THE AURUM VOICE IS YOURS")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2.5)
                    .foregroundStyle(Theme.goldMid)
                    .padding(.top, 6)
            } else {
                Button {
                    showEliteBoutique = true
                } label: {
                    Text("ASCEND TO ÉLITE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Theme.goldLight)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .overlay(
                            Capsule().stroke(Theme.goldMid.opacity(0.55), lineWidth: 1)
                        )
                }
                .padding(.top, 8)
            }
        }
    }

    private var crownButton: some View {
        Button {
            showEliteBoutique = true
        } label: {
            Image(systemName: "crown.fill")
                .font(.system(size: 15))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldMid]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(11)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Theme.goldMid.opacity(0.5), lineWidth: 1))
                .shadow(color: Theme.goldMid.opacity(store.isElite ? 0.55 : 0.2), radius: 10)
        }
        .accessibilityLabel(store.isElite ? "Élite boutique" : "Upgrade to Élite")
    }
}

/// The gallery: near-black obsidian with a warm ember glow rising behind
/// the instrument.
struct ObsidianBackground: View {
    var body: some View {
        ZStack {
            Theme.obsidianDeep

            RadialGradient(
                gradient: Gradient(colors: [Theme.ember.opacity(0.6), .clear]),
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 30,
                endRadius: 430
            )

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.35),
                    .clear,
                    .clear,
                    Color.black.opacity(0.55),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreManager())
}
