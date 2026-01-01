import Foundation
import StoreKit

/// Manages premium subscription state using StoreKit 2
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published State

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var isTrialActive: Bool = false
    @Published private(set) var trialDaysRemaining: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?

    // MARK: - Products

    @Published private(set) var premiumProduct: Product?

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
            updateTrialStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Purchase premium lifetime
    func purchasePremium() async throws {
        guard let product = premiumProduct else {
            throw SubscriptionError.productNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            Theme.successHaptic()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await updateSubscriptionStatus()

        if isPremium {
            Theme.successHaptic()
        }
    }

    /// Refresh subscription and trial status
    func refresh() async {
        await updateSubscriptionStatus()
        updateTrialStatus()
    }

    // MARK: - Private Methods

    private func loadProducts() async {
        do {
            let products = try await Product.products(for: [PremiumFeatures.premiumLifetimeProductID])
            premiumProduct = products.first
        } catch {
            self.error = error
        }
    }

    private func updateSubscriptionStatus() async {
        // Check for purchased non-consumable
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == PremiumFeatures.premiumLifetimeProductID {
                    isPremium = true
                    isTrialActive = false
                    syncCachedPremiumAccess()
                    return
                }
            }
        }
        isPremium = false
        syncCachedPremiumAccess()
    }

    /// Sync premium access status to AppSettings for non-MainActor access
    private func syncCachedPremiumAccess() {
        AppSettings.shared.cachedHasPremiumAccess = hasPremiumAccess
    }

    private func updateTrialStatus() {
        // Premium users don't need trial
        guard !isPremium else {
            isTrialActive = false
            trialDaysRemaining = 0
            syncCachedPremiumAccess()
            return
        }

        let trialStartDate = AppSettings.shared.trialStartDate

        // First launch - start trial
        if trialStartDate == nil {
            AppSettings.shared.trialStartDate = Date()
            isTrialActive = true
            trialDaysRemaining = PremiumFeatures.trialDurationDays
            syncCachedPremiumAccess()
            return
        }

        // Calculate remaining trial days
        let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: trialStartDate!,
            to: Date()
        ).day ?? 0

        let remaining = PremiumFeatures.trialDurationDays - daysSinceStart

        if remaining > 0 {
            isTrialActive = true
            trialDaysRemaining = remaining
        } else {
            isTrialActive = false
            trialDaysRemaining = 0
        }

        syncCachedPremiumAccess()
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Computed Access Properties

extension SubscriptionManager {
    /// Whether user has premium access (purchased OR trial active)
    var hasPremiumAccess: Bool {
        isPremium || isTrialActive
    }

    /// Formatted price string
    var formattedPrice: String {
        premiumProduct?.displayPrice ?? "£19.99"
    }

    /// Status text for display
    var statusText: String {
        if isPremium {
            return "Premium Active"
        } else if isTrialActive {
            return "\(trialDaysRemaining) days left in trial"
        } else {
            return "Free"
        }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Premium product not found. Please try again later."
        case .verificationFailed:
            return "Purchase verification failed. Please contact support."
        case .purchaseFailed:
            return "Purchase could not be completed. Please try again."
        }
    }
}
