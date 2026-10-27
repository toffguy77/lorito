import SwiftUI
import Domain
import DesignSystem

/// Ongoing settings: change the target level and theme selection after
/// onboarding. Changing the level re-derives the selectable themes; any
/// studyable change is persisted and triggers a `daily-plan` recompute. The
/// non-empty-scope guard blocks persisting an unstudyable selection.
public struct SettingsView: View {
    @State private var model: ScopeSelectionModel
    private let reminders: ReminderService?
    @Environment(\.loritoUITesting) private var uiTesting

    public init(model: ScopeSelectionModel, reminders: ReminderService? = nil) {
        _model = State(initialValue: model)
        self.reminders = reminders
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                if let reminders {
                    NavigationLink {
                        RemindersView(service: reminders)
                    } label: {
                        settingsRow("Напоминания", systemImage: "bell")
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    settingsRow("О приложении", systemImage: "info.circle")
                }
                .buttonStyle(.plain)

                analyticsSection

                section("Уровень") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LoritoSpacing.sm) {
                        ForEach(model.allLevels) { level in
                            SelectableChip(
                                title: level.rawValue,
                                isSelected: model.includedLevels.contains(level)
                            ) {
                                model.selectLevel(level)
                                persist()
                            }
                        }
                    }
                }

                section("Темы") {
                    LazyVStack(spacing: LoritoSpacing.xs) {
                        ForEach(model.availableThemes) { theme in
                            SelectableChip(
                                title: "\(theme.level.rawValue) · \(theme.title)",
                                isSelected: model.isThemeSelected(theme.id)
                            ) {
                                let wasSelected = model.isThemeSelected(theme.id)
                                model.toggleTheme(theme.id)
                                // Roll back a toggle that would empty the scope.
                                if !persist(), wasSelected {
                                    model.toggleTheme(theme.id)
                                }
                            }
                        }
                    }

                    if !model.isStudyable {
                        Text("Выберите хотя бы одну тему.")
                            .font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.dangerText)
                    }
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.vertical, LoritoSpacing.lg)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Настройки")
    }

    /// Persist the current working scope (guarded). Returns whether it persisted.
    @discardableResult
    private func persist() -> Bool {
        model.persist()
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text(title)
                .loritoStyle(.label)
                .foregroundStyle(LoritoColor.textSecondary)
            content()
        }
    }

    /// Device-local consent for anonymous usage analytics.
    private var analyticsSection: some View {
        let analytics = AnalyticsService.shared
        return VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Toggle(isOn: Binding(get: { analytics.isEnabled }, set: { analytics.setEnabled($0) })) {
                Text("Помогать улучшать Lorito")
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.textPrimary)
            }
            .tint(LoritoColor.accent)
            .accessibilityIdentifier("analyticsToggle")
            Text("Анонимная статистика использования: какие экраны открываются и как проходят занятия. Без аккаунта, без текста карточек и личных данных. Настройка хранится только на этом устройстве.")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
            Link("Политика конфиденциальности", destination: URL(string: "https://toffguy77.github.io/lorito/privacy.html")!)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.accent)
            if uiTesting {
                Text("\(analytics.queue.records.count)")
                    .font(LoritoFont.caption)
                    .accessibilityIdentifier("analytics.queueCount")
            }
        }
        .padding(LoritoSpacing.md)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
    }

    private func settingsRow(_ title: String, systemImage: String) -> some View {
        HStack(spacing: LoritoSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(LoritoColor.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(LoritoColor.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, LoritoSpacing.md)
        .frame(minHeight: LoritoLayout.primaryButtonHeight)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        .contentShape(Rectangle())
    }
}
