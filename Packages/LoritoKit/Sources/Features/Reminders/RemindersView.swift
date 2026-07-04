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
    @State private var newTime = Date()

    public init(service: ReminderService) {
        _service = State(initialValue: service)
    }

    /// Bind the toggle straight to the observed config so state stays in sync
    /// with persistence (no local mirror that can desync on re-entry).
    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { service.config.enabled },
            set: { on in
                Task {
                    if on { await service.enable(times: []) } else { await service.disable() }
                }
            }
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                Toggle(isOn: enabledBinding) {
                    Text("Ежедневные напоминания")
                        .font(LoritoFont.heading)
                        .foregroundStyle(LoritoColor.textPrimary)
                }
                .tint(LoritoColor.accent)
                .accessibilityIdentifier("remindersEnabledToggle")

                if service.authorization == .denied {
                    deniedGuidance
                }

                if service.persistenceFailed {
                    saveFailedGuidance
                }

                if service.config.enabled {
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

    /// Inline wheel picker on iOS (directly accessible to UI tests and quicker to
    /// pick a time); plain picker elsewhere.
    @ViewBuilder
    private var addTimePicker: some View {
        let picker = DatePicker("", selection: $newTime, displayedComponents: .hourAndMinute)
            .labelsHidden()
        #if os(iOS)
        picker.datePickerStyle(.wheel)
        #else
        picker
        #endif
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
                        .accessibilityIdentifier("reminderTimeRow")
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

            // Wheel picker above a full-width button: the inline wheel is greedy,
            // so keeping the button on its own row preserves its hit area.
            VStack(spacing: LoritoSpacing.sm) {
                addTimePicker
                Button("Добавить") {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                    Task { await service.addTime(ReminderTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)) }
                }
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LoritoSpacing.xs)
                .background(LoritoColor.accent, in: Capsule())
                .buttonStyle(.plain)
            }
        }
    }

    private var saveFailedGuidance: some View {
        Text("Не удалось сохранить настройки напоминаний. Проверьте место на устройстве и попробуйте снова.")
            .font(LoritoFont.caption)
            .foregroundStyle(LoritoColor.danger)
            .padding(LoritoSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoritoColor.dangerSoft, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
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
