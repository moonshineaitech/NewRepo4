# GONG

**One sound. Infinite status.**

Gong is a $100 iOS instrument that does exactly one thing: when you strike the
gong in the middle of the screen, it makes a magnificent gong sound and an
equally magnificent animation. That's it. That's the app.

For those who require more, the **Gong Élite** upgrade ($999.99, one-time)
re-finishes the instrument in 24-karat gold, retunes it to the brighter
*Aurum* voice, turns every strike burst white-gold, and engraves the Élite
crest beneath the disc. Forever.

---

## What's inside

| | |
|---|---|
| **UI** | Pure SwiftUI. Obsidian gallery background with drifting gold dust, a bronze gong suspended on silk cords beneath a gilded beam, and a Metal `colorEffect` shader that sweeps a light glint across the metal. |
| **Interaction** | Touch the gong and a ceremonial mallet appears and draws back while you hold — release to strike. Hold longer, strike harder. |
| **Strike choreography** | Damped-spring wobble on the ropes, contact flash, three expanding ripples, and a deterministic burst of gold particles. Every animation is a pure function of time driven by a single `TimelineView` — there is no animation state to desynchronize. |
| **Sound** | No audio files. The gong is *synthesized at launch* from 14 inharmonic partials (chau-gong ratios around G2) with per-partial decay, post-strike bloom, phase-modulated shimmer, a mallet-felt noise transient, and a Haas-widened stereo image, played through an 8-voice pool into a large-hall reverb. The Élite instrument is retuned ~2.3 semitones brighter. |
| **Haptics** | Core Haptics: a hard transient at contact plus a decaying rumble that mirrors the ring-down. Falls back to `UIImpactFeedbackGenerator`. |
| **Commerce** | StoreKit 2 non-consumable (`com.moonshineai.gong.elite999`), verified against `Transaction.currentEntitlements` on every launch, with restore support and an offline-friendly cache. |
| **Ledger** | Every resonance is counted and displayed in Roman numerals, as is proper. |

## Requirements

- Xcode 16 or newer (the project uses the modern buildable-folder format)
- iOS 17.0+ deployment target
- No dependencies, no packages, no audio assets. Clone and press ⌘R.

## Building & running

1. Open `Gong.xcodeproj` in Xcode.
2. Select the `Gong` scheme and any iOS 17+ simulator or device.
3. Run. Strike. Ascend.

### Testing the $999.99 purchase locally

1. Edit the `Gong` scheme → Run → Options → **StoreKit Configuration** → select `Gong.storekit`.
2. Run the app, open the crown (top right), and purchase Gong Élite with the
   local test store — no money changes hands, no App Store Connect setup needed.

## Shipping to TestFlight

1. In Xcode, set your **Team** under Signing & Capabilities (bundle ID
   `com.moonshineai.gong`, or change it to match your account).
2. In [App Store Connect](https://appstoreconnect.apple.com):
   - Create the app record for the bundle ID.
   - Add an **In-App Purchase** → Non-Consumable with product ID
     `com.moonshineai.gong.elite999`, price **$999.99**.
   - Set the app's price to **$99.99**.
3. Product → **Archive**, then **Distribute App** → App Store Connect → Upload.
4. The build appears under TestFlight within minutes. Add internal testers and
   strike at will. (`ITSAppUsesNonExemptEncryption` is already set to `NO`, so
   there's no export-compliance interruption.)

The shared `Gong` scheme is committed, so the project is also ready for
Xcode Cloud or any CI archive pipeline out of the box.

## Repository layout

```
Gong.xcodeproj/          Xcode project (buildable-folder format + shared scheme)
Gong/
  GongApp.swift          Entry point
  ContentView.swift      Gallery chrome: header, resonance ledger, crown
  GongStageView.swift    The stage: gong face, ropes, beam, flash, gesture
  EffectsViews.swift     Ripples, particle bursts, ambient dust, the mallet
  GongModel.swift        Strike model; all animation curves as functions of time
  GongSoundEngine.swift  The synthesized instrument (AVAudioEngine)
  GongHaptics.swift      Core Haptics strike patterns
  StoreManager.swift     StoreKit 2: the Élite upgrade
  EliteBoutiqueView.swift The paywall — sorry, the boutique
  Theme.swift            Design language: obsidian, bronze, aurum
  Shaders.metal          The sweeping gold glint
  Gong.storekit          Local StoreKit test configuration
  Assets.xcassets        App icon, accent color
AppStore/                Launch copy, pricing, review notes
PRIVACY.md               (Spoiler: we collect nothing)
```

## A note on Replit

This repository is plain files — clone it anywhere, including Replit, for
browsing and editing. Building an iOS app binary requires Xcode on macOS
(or Xcode Cloud); there is no way around that, even for a gong.
