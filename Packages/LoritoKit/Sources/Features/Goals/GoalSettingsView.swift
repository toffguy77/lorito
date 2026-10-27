import SwiftUI
import Domain
import DesignSystem

/// Settings → «Цель»: level goal, exam date, the "DELE A2" preset, mark done, remove.
public struct GoalSettingsView: View {
    @Bindable var model: GoalSettingsModel

    public init(model: GoalSettingsModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            Section {
                Button {
                    model.applyDeleA2Preset()
                } label: {
                    Label("DELE A2 к дате экзамена", systemImage: "graduationcap")
                }
                .disabled(!model.canSaveExam)
                .accessibilityIdentifier("goal.preset.deleA2")
            } header: {
                Text("Быстрый выбор")
            } footer: {
                Text("Цель A2 и экзамен DELE A2 на одну дату — дату выберите ниже, в разделе «Экзамен».")
            }

            Section("Уровень к дате") {
                Picker("Уровень", selection: $model.goalLevel) {
                    ForEach(model.goalLevels) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Дата", selection: $model.goalDate, displayedComponents: .date)
                Button(model.levelGoal == nil ? "Поставить цель" : "Сохранить") { model.saveLevelGoal() }
                    .disabled(!model.canSaveGoal)
                    .accessibilityIdentifier("goal.saveLevel")
                if !model.canSaveGoal {
                    Text("Дата должна быть позже сегодняшней.")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.dangerText)
                }
                if model.levelGoal != nil {
                    Button("Удалить цель", role: .destructive) { model.removeLevelGoal() }
                        .accessibilityIdentifier("goal.removeLevel")
                }
            }

            Section("Экзамен") {
                Picker("Экзамен", selection: $model.examKind) {
                    ForEach(ExamKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                DatePicker("Дата экзамена", selection: $model.examDate, displayedComponents: .date)
                Button(model.exam == nil ? "Добавить экзамен" : "Сохранить") { model.saveExam() }
                    .disabled(!model.canSaveExam)
                if let exam = model.exam {
                    if !exam.done {
                        Button("Экзамен сдан") { model.markExamDone() }
                    }
                    Button("Удалить экзамен", role: .destructive) { model.removeExam() }
                        .accessibilityIdentifier("goal.removeExam")
                }
            }
        }
        .navigationTitle("Цель")
        .onAppear { model.reload() }
    }
}
