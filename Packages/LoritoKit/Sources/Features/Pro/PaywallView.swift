import SwiftUI
import StoreKit
import Domain
import DesignSystem

/// Honest paywall (Russian): what Pro adds, each product's price and renewal
/// terms, any introductory offer, Terms and Privacy, restore and close. No
/// external payment links, countdowns or invented discounts.
public struct PaywallView: View {
    let service: PurchaseService
    let entry: PaywallEntry
    let onClose: () -> Void
    @State private var busy = false
    @State private var message: String?

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://toffguy77.github.io/lorito/privacy.html")!

    public init(service: PurchaseService, entry: PaywallEntry, onClose: @escaping () -> Void) {
        self.service = service
        self.entry = entry
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                    Text("Lorito Pro").loritoStyle(.title).foregroundStyle(LoritoColor.textPrimary)
                    Text("Всё остальное в Lorito бесплатно и останется бесплатным. Pro добавляет только подготовку к экзаменам:")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                        feature("graduationcap", "Путь к DELE A2 и CCSE: полный набор заданий по разделам")
                        feature("timer", "Пробные экзамены с таймером и разбором")
                        feature("chart.line.uptrend.xyaxis", "Готовность к экзамену по разделам")
                    }
                    products
                    if let message {
                        Text(message).font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                    }
                    Button("Восстановить покупки") {
                        Task {
                            busy = true
                            let outcome = await service.restore()
                            busy = false
                            switch outcome {
                            case .restored: onClose()
                            case .nothingToRestore: message = "Покупок для восстановления не найдено."
                            case .failed: message = "Не удалось связаться с App Store. Попробуйте позже."
                            }
                        }
                    }
                    .font(LoritoFont.bodyStrong)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .accessibilityIdentifier("paywall.restore")
                    HStack(spacing: LoritoSpacing.md) {
                        Link("Условия использования", destination: Self.termsURL)
                        Link("Конфиденциальность", destination: Self.privacyURL)
                    }
                    .font(LoritoFont.caption)
                }
                .padding(LoritoSpacing.screenGutter)
                .frame(maxWidth: LoritoLayout.readingWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(LoritoColor.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", action: onClose).accessibilityIdentifier("paywall.close")
                }
            }
        }
        .task {
            AnalyticsService.shared.record(.paywallShown(entry: entry))
            await service.loadProducts()
        }
    }

    @ViewBuilder
    private var products: some View {
        switch service.availability {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .unavailable:
            Text("Lorito Pro пока недоступен в вашем регионе")
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityIdentifier("paywall.unavailable")
        case .available(let list):
            VStack(spacing: LoritoSpacing.sm) {
                ForEach(list) { product in
                    Button {
                        Task {
                            busy = true
                            let outcome = await service.purchase(product.id)
                            busy = false
                            switch outcome {
                            case .purchased: onClose()
                            case .pending: message = "Покупка ожидает подтверждения."
                            case .failed: message = "Покупка не прошла. Попробуйте ещё раз."
                            case .cancelled: break
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(product.displayName).font(LoritoFont.bodyStrong)
                                Spacer()
                                Text(product.displayPrice).font(LoritoFont.bodyStrong)
                            }
                            Text(product.terms).font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                            if let intro = product.introOffer {
                                Text(intro).font(LoritoFont.caption).foregroundStyle(LoritoColor.accent)
                            }
                        }
                        .foregroundStyle(LoritoColor.textPrimary)
                        .padding(LoritoSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                    .accessibilityIdentifier("paywall.buy.\(product.id)")
                }
            }
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: LoritoSpacing.sm) {
            Image(systemName: icon).foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
            Text(text).font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Shows `content` when `feature` is entitled, otherwise `locked` (which opens
/// the paywall). Used only by exam content outside the preview set.
public struct ProGate<Content: View, Locked: View>: View {
    let feature: ProFeature
    let service: PurchaseService
    @ViewBuilder let content: () -> Content
    @ViewBuilder let locked: () -> Locked

    public init(_ feature: ProFeature, service: PurchaseService, @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder locked: @escaping () -> Locked) {
        self.feature = feature
        self.service = service
        self.content = content
        self.locked = locked
    }

    public var body: some View {
        if service.isEntitled(feature) { content() } else { locked() }
    }
}

/// Settings «Lorito Pro»: status, restore, manage subscription.
struct ProSettingsSection: View {
    let service: PurchaseService
    @State private var showPaywall = false
    @State private var showManage = false
    @State private var restoreMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text(service.isEntitled(.examPath) ? "Lorito Pro активен" : "Lorito Pro: подготовка к DELE и CCSE")
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityIdentifier("settings.pro.status")
            if !service.isEntitled(.examPath) {
                Button("Подробнее") { showPaywall = true }
                    .font(LoritoFont.bodyStrong)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .accessibilityIdentifier("settings.pro.open")
            } else {
                Button("Управлять подпиской") { showManage = true }
                    .font(LoritoFont.bodyStrong)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
            }
            Button("Восстановить покупки") {
                Task {
                    let outcome = await service.restore()
                    restoreMessage = outcome == .restored ? "Покупки восстановлены." :
                        outcome == .nothingToRestore ? "Покупок для восстановления не найдено." : "Не удалось связаться с App Store."
                }
            }
            .font(LoritoFont.body)
            .frame(minHeight: LoritoLayout.minTouchTarget)
            if let restoreMessage {
                Text(restoreMessage).font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
            }
        }
        .padding(LoritoSpacing.md)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        .sheet(isPresented: $showPaywall) {
            PaywallView(service: service, entry: .settings) { showPaywall = false }
        }
        .manageSubscriptions(isPresented: $showManage)
    }
}

private extension View {
    @ViewBuilder
    func manageSubscriptions(isPresented: Binding<Bool>) -> some View {
        #if os(iOS)
        manageSubscriptionsSheet(isPresented: isPresented)
        #else
        self
        #endif
    }
}
