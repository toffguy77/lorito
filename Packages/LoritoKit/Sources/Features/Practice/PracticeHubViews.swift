import SwiftUI
import Domain
import DesignSystem

/// One free-practice entry (practice-hub): title, «доступно X из Y», a lock
/// while Pro is required. Choosing it starts the session, explains an empty
/// state or presents the paywall.
struct PracticeEntryButton: View {
    let model: PracticeHubModel
    let mode: PracticeMode
    let title: String
    let systemImage: String
    let identifier: String
    @Environment(PurchaseService.self) private var purchases: PurchaseService?
    @Environment(\.speechService) private var speech
    @Environment(\.practiceSessionDidEnd) private var practiceSessionDidEnd
    @State private var session: ExerciseSessionModel?
    @State private var emptyMessage: String?
    @State private var paywall = false

    var body: some View {
        let availability = model.availability(mode)
        let unlocked = model.isUnlocked(purchases)
        Button(action: choose) {
            HStack(spacing: LoritoSpacing.sm) {
                Image(systemName: systemImage).foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                    Text("доступно \(availability.available) из \(availability.total)")
                        .font(LoritoFont.caption).monospacedDigit()
                        .foregroundStyle(LoritoColor.textSecondary)
                }
                Spacer()
                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .foregroundStyle(LoritoColor.textSecondary).accessibilityHidden(true)
            }
            .padding(LoritoSpacing.md)
            .frame(minHeight: LoritoLayout.minTouchTarget)
            .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .onAppear { model.refresh() }
        .alert("Пока нечего тренировать", isPresented: Binding(get: { emptyMessage != nil },
                                                               set: { if !$0 { emptyMessage = nil } })) {
            Button("Понятно", role: .cancel) { emptyMessage = nil }
        } message: {
            Text(emptyMessage ?? "")
        }
        .sheet(isPresented: $paywall) {
            if let purchases {
                PaywallView(service: purchases, entry: .practice) { paywall = false }
            }
        }
        .focusModeCover(item: $session) { s in
            ExerciseSessionView(model: s) {
                session = nil
                model.refresh()
                practiceSessionDidEnd()
            }
        }
    }

    private func choose() {
        switch model.start(mode, purchases: purchases, hasSpanishVoice: speech?.hasSpanishVoice ?? false) {
        case .session(let s): session = s
        case .empty(let message): emptyMessage = message
        case .paywall: paywall = purchases != nil
        }
    }
}

/// «Практика» from Today: mixed and weak-spot sessions; theme and level
/// practice live in the Catalog.
struct PracticeHubView: View {
    let model: PracticeHubModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                Text("Упражнения по карточкам, которые вы уже изучили. Новые упражнения открываются по мере изучения карточек.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PracticeEntryButton(model: model, mode: .mixed, title: "Смешанная",
                                    systemImage: "shuffle", identifier: "practice.mode.mixed")
                PracticeEntryButton(model: model, mode: .weakSpots, title: "Слабые места",
                                    systemImage: "scope", identifier: "practice.mode.weak")
                Text("Практика по теме и по уровню — в Каталоге.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(LoritoSpacing.screenGutter)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Практика")
        .onAppear { model.refresh() }
    }
}

extension PracticeHubModel: Identifiable {
    public nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}
