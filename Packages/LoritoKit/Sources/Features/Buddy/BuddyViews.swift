import SwiftUI
import CloudKit
import Domain
import DesignSystem

/// «Учиться вместе» on Progress: invite, waiting, the partner's week, the shared
/// streak and the nudge.
public struct BuddyCard: View {
    let model: BuddyModel
    @State private var invite: BuddyInviteSheet?
    @State private var confirmLeave = false

    public init(model: BuddyModel) { self.model = model }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text("Учиться вместе")
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .padding(LoritoSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("buddy.card")
        .task { await model.refresh() }
        #if os(iOS)
        .sheet(item: $invite) { sheet in
            CloudSharingView(invite: sheet.invite).ignoresSafeArea()
        }
        #endif
        .confirmationDialog("Перестать учиться вместе?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Перестать", role: .destructive) { Task { await model.leave() } }
        } message: {
            Text("Общая серия и данные напарника исчезнут у вас обоих.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .unavailable:
            note("Нужен iCloud: войдите в Apple ID и включите iCloud для Lorito в Настройках. Без этого пригласить напарника нельзя.")
                .accessibilityIdentifier("buddy.unavailable")
        case .invite:
            note(Self.sharedExplanation)
            Button("Пригласить напарника") { Task { await openInvite() } }
                .buttonStyle(PrimaryButtonStyle(.ink))
                .accessibilityIdentifier("buddy.invite")
        case .waitingForPartner:
            note("Ждём, пока напарник примет приглашение.")
            HStack {
                Button("Отправить ссылку ещё раз") { Task { await openInvite() } }
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.accent)
                Spacer()
                Button("Отменить") { confirmLeave = true }
                    .foregroundStyle(LoritoColor.textSecondary)
            }
            .frame(minHeight: LoritoLayout.minTouchTarget)
        case .paired(let pair):
            paired(pair)
        }
    }

    static let sharedExplanation = "Напарник увидит только ваше имя, текущую серию, занимались ли вы сегодня и последние 7 дней. Карточки, ответы и прогресс по темам не передаются."

    private func paired(_ p: BuddyModel.Pair) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(p.partnerName).font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                Spacer()
                Text("серия \(RussianPlural.days(p.partnerStreak))")
                    .font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
            }
            Text(p.partnerStudiedToday ? "Сегодня: занятие есть" : "Сегодня: пока без занятий")
                .font(LoritoFont.caption)
                .foregroundStyle(p.partnerStudiedToday ? LoritoColor.accent : LoritoColor.textSecondary)
            HStack(spacing: LoritoSpacing.xxs) {
                ForEach(p.week, id: \.day) { d in
                    Circle()
                        .fill(d.studied ? LoritoColor.accent : LoritoColor.surfaceSunken)
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Последние 7 дней: \(p.week.filter(\.studied).count) из 7")
            Text("Общая серия: \(RussianPlural.days(p.sharedStreak))")
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityIdentifier("buddy.sharedStreak")
            if p.nudgedByPartnerToday {
                note("Напарник напомнил вам позаниматься сегодня.")
            }
            Button("Напомнить") { Task { await model.nudge() } }
                .buttonStyle(PrimaryButtonStyle(.ink))
                .disabled(!p.canNudge || model.isWorking)
                .accessibilityIdentifier("buddy.nudge")
            if !p.canNudge {
                note(p.partnerStudiedToday ? "У напарника сегодня уже есть занятие." : "Вы уже напомнили сегодня.")
            }
            Button("Перестать учиться вместе") { confirmLeave = true }
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
                .frame(minHeight: LoritoLayout.minTouchTarget)
                .accessibilityIdentifier("buddy.leave")
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(LoritoFont.caption)
            .foregroundStyle(LoritoColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func openInvite() async {
        guard let made = await model.invite(), made.share != nil else { return }
        invite = BuddyInviteSheet(invite: made)
    }
}

/// One line on Today once paired.
public struct BuddyTodayLine: View {
    let model: BuddyModel
    public init(model: BuddyModel) { self.model = model }

    public var body: some View {
        if case .paired(let p) = model.state {
            HStack(spacing: LoritoSpacing.xs) {
                Image(systemName: "person.2").foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
                Text("\(p.partnerName): \(p.partnerStudiedToday ? "сегодня занятие есть" : "сегодня пока без занятий") · общая серия \(RussianPlural.days(p.sharedStreak))")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("today.buddy")
        }
    }
}

private struct BuddyInviteSheet: Identifiable {
    let id = UUID()
    let invite: BuddyInvite
}

#if os(iOS)
/// `UICloudSharingController` for the zone-wide share (participants read-write).
private struct CloudSharingView: UIViewControllerRepresentable {
    let invite: BuddyInvite

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let c = UICloudSharingController(share: invite.share!, container: invite.container!)
        c.availablePermissions = [.allowReadWrite, .allowPrivate]
        return c
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}
}
#endif
