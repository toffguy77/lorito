import SwiftUI
import Domain
import DesignSystem
#if canImport(UIKit)
import UIKit
#endif

/// Enable reminders and manage daily times. Shows Settings guidance when
/// authorization is denied. Russian UI.
public struct RemindersView: View {
    @State private var service: ReminderService
    @State private var enabled: Bool
    @State private var newTime = Date()

    public init(service: ReminderService) {
        _service = State(initialValue: service)
        _enabled = State(initialValue: service.config.enabled)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                Toggle(isOn: $enabled) {
                    Text("Ежедневные напоминания")
                        .font(LoritoFont.heading)
                        .foregroundStyle(LoritoColor.textPrimary)
                }
                .tint(LoritoColor.accent)
                .onChange(of: enabled) { _, on in
                    Task {
                        if on { await service.enable(times: []) } else { await service.disable() }
                    }
                }

                if service.authorization == .denied {
                    deniedGuidance
                }

                if enabled {
                    timesSection
                }

                Spacer()
            }
            .padding(LoritoSpacing.lg)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Напоминания")
        .task { await service.refreshAuthorization() }
    }

    private var timesSection: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text("Время")
                .font(LoritoFont.label)
                .foregroundStyle(LoritoColor.textTertiary)

            ForEach(service.config.times, id: \.minutesFromMidnight) { time in
                HStack {
                    Text(String(format: "%02d:%02d", time.hour, time.minute))
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textPrimary)
                    Spacer()
                    Button {
                        Task { await service.removeTime(time) }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(LoritoColor.danger)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, LoritoSpacing.xxs)
            }

            HStack(spacing: LoritoSpacing.sm) {
                DatePicker("", selection: $newTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Button("Добавить") {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                    Task { await service.addTime(ReminderTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)) }
                }
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.vertical, LoritoSpacing.xs)
                .background(LoritoColor.accent, in: Capsule())
                .buttonStyle(.plain)
            }
        }
    }

    private var deniedGuidance: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Уведомления отключены")
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.danger)
            Text("Разрешите уведомления для Lorito в Настройках, чтобы получать напоминания.")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
            #if canImport(UIKit)
            Button("Открыть Настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(LoritoFont.body.weight(.semibold))
            .foregroundStyle(LoritoColor.onAccentSoft)
            #endif
        }
        .padding(LoritoSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.dangerSoft, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
    }
}
