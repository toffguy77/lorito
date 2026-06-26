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
                        HStack {
                            Text("Напоминания")
                                .font(LoritoFont.heading)
                                .foregroundStyle(LoritoColor.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(LoritoColor.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

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
                            .foregroundStyle(LoritoColor.danger)
                    }
                }
            }
            .padding(LoritoSpacing.lg)
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
                .font(LoritoFont.heading)
                .foregroundStyle(LoritoColor.textPrimary)
            content()
        }
    }
}
