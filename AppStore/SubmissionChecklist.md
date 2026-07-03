# Gong — App Store Submission Checklist

Everything Apple requires to ship Gong, with the **exact answer for this app**
next to each item. Fill the 🔧 placeholders with your real values before you
submit. Nothing here is generic filler — it's tuned to what Gong actually does
(one synthesized gong, no accounts, no data collection, one $999.99 IAP).

---

## 0. Accounts & prerequisites

- [ ] **Apple Developer Program** membership, active ($99/year).
- [ ] **Paid Apps Agreement** signed in App Store Connect → Business. **Required**
      because Gong is a paid app with a paid IAP; without it, nothing sells.
- [ ] **Banking & tax** forms complete (same Business section).
- [ ] Bundle ID **`com.moonshineai.gong`** registered (Certificates, IDs &
      Profiles → Identifiers). No special capabilities/entitlements needed —
      Gong uses no push, iCloud, sign-in, or background modes.

---

## 1. The technical requirements (in the binary)

- [x] **Privacy Manifest** — `Gong/PrivacyInfo.xcprivacy` is included and declares
      the one Required-Reason API Gong touches: `UserDefaults` (reason `CA92.1`,
      same-app access). This prevents the **ITMS-91053 "missing API declaration"**
      rejection. It also declares no tracking and no data collection.
- [x] **Export compliance** — `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`
      is set in the project, so uploads skip the encryption questionnaire. (Gong
      uses no encryption beyond Apple's own HTTPS/StoreKit.)
- [x] **Restore mechanism** — the boutique has a **Restore Purchases** button.
      **Required by Guideline 3.1.1** for the non-consumable Élite upgrade.
- [x] **App icon** — 1024×1024, no alpha, included in the asset catalog.
- [x] **Launch screen** — generated (`UILaunchScreen`), so the app is not let-boxed.
- [x] **Full device support** — iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`),
      portrait. iOS 17.0 minimum.
- [ ] Build the archive with a **Distribution** signing certificate & App Store
      provisioning profile (Xcode → automatic signing handles this once your Team
      is selected).

---

## 2. App Privacy ("nutrition label") — App Store Connect → App Privacy

Answer the questionnaire exactly like this:

- **Do you or your third-party partners collect data from this app?** → **No.**
- That single answer produces a **"Data Not Collected"** label. Done.

Rationale you can paste if asked: *Gong has no analytics, no accounts, and no
network calls of its own. The resonance count and the Élite-owned flag are stored
only in on-device UserDefaults and never transmitted. Purchases are processed by
Apple; the developer never receives payment or identity data.*

- [ ] **Privacy Policy URL** (required field): 🔧 host `docs/privacy.html` and
      paste its URL. Fastest path: enable **GitHub Pages** on this repo
      (Settings → Pages → deploy from `main` / `docs` folder) →
      `https://moonshineaitech.github.io/<repo>/privacy.html`. Or host at
      `https://moonshineai.com/gong/privacy`.

---

## 3. Account deletion — **not required for Gong**

Guideline **5.1.1(v)** requires in-app account deletion **only for apps that let
users create an account.** Gong has **no account, no sign-in, and no server**, so
the requirement does not apply.

- [x] Nothing to build.
- [ ] To pre-empt any reviewer question, the **App Review notes** (section 7)
      state plainly: *"Gong has no user accounts, login, or server-side data.
      There is no account to delete; deleting the app removes the only two
      locally-stored values."* Include it and this never comes up.

---

## 4. App information — App Store Connect → App Information

- **Name:** Gong
- **Subtitle:** One sound. Infinite status.
- **Category:** Primary **Entertainment**; Secondary (optional) Lifestyle.
- **Content Rights:** you own or have licensed all content → **Yes** (the sound is
  synthesized in-app; the icon and art are original).
- **Age Rating:** answer every questionnaire item **None / No** → **4+**. Gong has
  no violence, no mature themes, no web access, no user-generated content, no
  gambling.
- **Support URL** (required): 🔧 host `docs/support.html` → its URL, or
  `https://moonshineai.com/gong/support`.
- **Marketing URL** (optional): 🔧 e.g. `https://moonshineai.com/gong`.

---

## 5. Pricing & the in-app purchase

- [ ] **App price: $99.99** (the highest standard tier below $100).
- [ ] **In-App Purchase** → **Non-Consumable**:
  - Reference Name: `Gong Elite Upgrade`
  - Product ID: **`com.moonshineai.gong.elite999`** (must match the code &
    `Gong.storekit` exactly — it does).
  - Price: **$999.99**.
  - Display Name: **Gong Élite**
  - Description: *24-karat finish, the Aurum voice, golden radiance, and the
    Élite crest. Forever.*
  - **Review screenshot** (required for IAP): a shot of the boutique sheet —
    grab `04-hard-strike` or the boutique from the CI **`gong-evidence`**
    artifact, or screenshot the paywall on a simulator.
  - Review notes: *Cosmetic + audio upgrade. Re-skins the instrument gold and
    retunes the synthesized voice. Restorable via the boutique's Restore button.*
- [ ] Submit the IAP **with the app build** (first submission reviews them together).

---

## 6. Media — screenshots & preview

- [ ] **Screenshots (required).** As of 2025 Apple requires **one 6.9"/6.7"
      iPhone set**; iPad sets required only if you advertise iPad. Pull frames
      from the CI **`gong-evidence`** artifact (the UI test captures the gallery,
      strikes, resonance, and ring-down) or capture on a simulator at the required
      resolution. Recommended order: gallery at rest → mid-strike with ripples →
      the Élite gold gong → the boutique.
- [ ] **App Preview video (optional but high-value here):** a 15–30s clip of a
      strike + ring-down sells the sound better than stills. Record with
      `xcrun simctl io booted recordVideo`.
- **Promotional text (updatable without a build):** *One sound. Infinite status.
  Strike the most beautiful gong on the App Store.*

---

## 7. App Review notes — App Store Connect → Version → Notes for Review

Paste this. It defuses the two things a reviewer might flag (the price, and
"where's the account deletion"):

> Gong is a deliberately single-purpose premium instrument: touch the gong and it
> sounds and animates. The experience is fully synthesized in real time — 14
> inharmonic partials rendered at launch, Core Haptics, a Metal shimmer shader,
> a wind-up mallet, Siri/Action-button support ("Strike the Gong"), and full
> VoiceOver + Reduce Motion support. All advertised functionality is present and
> works offline.
>
> There are **no user accounts, no login, and no server**. No data is collected
> or transmitted. The only stored state is an on-device strike count and the
> Élite-owned flag. There is therefore no account to delete (Guideline 5.1.1(v)
> does not apply); deleting the app removes that local state.
>
> **Gong Élite ($999.99)** is a non-consumable cosmetic + audio upgrade
> (gold finish, brighter "Aurum" voice, Élite crest). It is restorable via the
> "Restore Purchases" button in the boutique.
>
> No demo account is needed. To test Élite in review, use the sandbox purchase
> flow from the crown button (top-right) → Become Élite.

- **Sign-in required?** → **No** (leave demo credentials blank).
- **Contact:** 🔧 your name + phone + `ryan@moonshineai.com`.

---

## 8. The honest risk: Guideline 4.2 / 4.3 (minimum functionality)

A high-priced, single-function app is the classic 4.2 ("minimum functionality")
and 4.3 ("spam") rejection — this is the *"I Am Rich"* lineage, and it is the
**most likely reason Gong gets bounced**, far more than any missing form.

**What's in our favor** (and worth emphasizing in the review notes above): Gong
isn't an empty shell — it's a genuinely deep, polished instrument (real-time
synthesis, haptics, shaders, Siri intents, accessibility). That craft is the
argument that it clears the "minimum functionality" bar.

**If rejected under 4.2/4.3,** don't just resubmit — reply in Resolution Center
pointing to the specific engineered features (the synthesis engine, haptic
ring-down, App Intents, accessibility) as evidence of substance. Consider these
pre-emptive strengtheners (all optional, none shipped yet — ask and I'll add):
- an **About/credits screen** describing the instrument's construction (makes the
  depth visible to a reviewer in 5 seconds),
- a couple more **secondary interactions** (e.g. a long-press "sustain," a
  double-strike flourish) so the single screen demonstrably rewards exploration.

Pricing note: Apple rarely rejects purely *for* a high price, but a high price
raises the bar it applies under 4.2. Going in eyes-open is the point of this
section.

---

## 9. Pre-flight build checklist

- [ ] Xcode → set your **Team** under Signing & Capabilities (target: Gong).
- [ ] Bump **Version** (`MARKETING_VERSION`, currently 1.0) and **Build**
      (`CURRENT_PROJECT_VERSION`, currently 1) if resubmitting.
- [ ] **Product → Archive**, then **Distribute App → App Store Connect → Upload**.
- [ ] Verify the upload shows **no ITMS warnings** (the privacy manifest should
      clear the API-declaration one).
- [ ] In App Store Connect, attach the build to the version, complete sections
      2–7 above, and **Submit for Review**.
- [ ] TestFlight: the build is testable internally within minutes of upload —
      strike it on a real device first to confirm sound + haptics + the sandbox
      Élite purchase before you submit for review.

---

*Green boxes above are already handled in this repo. The unchecked ones need your
Apple account, your hosted URLs, and the archive step on a Mac (or iPad Swift
Playgrounds, or a cloud Mac).*
