import Foundation
import StoreKit

/// StoreKit 2 manager for the single Gong Élite non-consumable upgrade.
///
/// The app itself is a paid download; the Élite upgrade re-finishes the
/// instrument in 24-karat gold, retunes it to the Aurum voice, and engraves
/// the crest. Ownership is verified against `Transaction.currentEntitlements`
/// on every launch and mirrored to `UserDefaults` so the gold appears
/// instantly on cold start.
@MainActor
final class StoreManager: ObservableObject {

    static let eliteProductID = "com.moonshineai.gong.elite999"
    private static let eliteCacheKey = "gong.elite.owned"

    @Published private(set) var isElite: Bool
    @Published private(set) var eliteProduct: Product?
    @Published private(set) var purchaseInFlight = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        isElite = UserDefaults.standard.bool(forKey: Self.eliteCacheKey)

        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update: update)
            }
        }

        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.eliteProductID])
            eliteProduct = products.first
        } catch {
            lastError = "The boutique is unreachable: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchaseElite() async {
        guard !purchaseInFlight else { return }

        if eliteProduct == nil {
            await loadProduct()
        }
        guard let product = eliteProduct else {
            lastError = "The Élite upgrade could not be located. Please try again."
            return
        }

        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                setElite(true)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                lastError = "Your ascension is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastError = "The purchase could not be completed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore / entitlements

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            // Sync can throw if the user cancels the App Store sign-in; the
            // entitlement pass below is still worth running.
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.eliteProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        // Never revoke gold mid-session unless the store says so explicitly.
        setElite(owned || isEliteRevocationExempt(owned: owned))
    }

    private func isEliteRevocationExempt(owned: Bool) -> Bool {
        // If the entitlement pass found nothing but the network was never
        // reachable, keep the cached state rather than stripping the gold.
        !owned && eliteProduct == nil && isElite
    }

    private func handle(update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        if transaction.productID == Self.eliteProductID {
            setElite(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setElite(_ value: Bool) {
        isElite = value
        UserDefaults.standard.set(value, forKey: Self.eliteCacheKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
