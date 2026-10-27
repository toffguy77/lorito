import SwiftUI
import Domain
import DesignSystem

/// The Today screen: summary of the day's queue, a start action, and distinct
/// empty / all-done states. Presents the study session modally.
public struct TodayView: View {
    @State private var model: TodayModel
    @State private var session: StudySessionModel?
    private let catalog: ContentCatalog
    private let store: UserDataStore
    private let onSessionComplete: () -> Void

    public init(
        store: UserDataStore,
        catalog: ContentCatalog,
        onSessionComplete: @escaping () -> Void = {}
    ) {
        self.store = store
        self.catalog = catalog
        self.onSessionComplete = onSessionComplete
        _model = State(initialValue: TodayModel(store: store, catalog: catalog))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                header

                if model.hasWork {
                    activeState
                } else if model.isAllDone {
                    message(mark: "¡", markColor: LoritoColor.accent,
                            title: "Всё на сегодня!", subtitle: "Вы прошли все карточки дня.")
                } else {
                    message(mark: "¿", markColor: LoritoColor.textSecondary,
                            title: "Пока нечего изучать", subtitle: "Загляните позже — карточки появятся, когда придёт срок.")
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.lg)
            .padding(.bottom, LoritoSpacing.xl)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
        .focusModeCover(item: $session, onDismiss: {
            model.refresh()
            onSessionComplete()
        }) { session in
            StudySessionView(model: session) { self.session = nil }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ru_RU"))).capitalizedFirst)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
            Text("¡Hola!")
                .loritoStyle(.display)
                .foregroundStyle(LoritoColor.textPrimary)
                .loritoTitleFit(lines: 1)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var activeState: some View {
        PlanHeroCard(
            total: model.remaining.count,
            caption: model.summary,
            parts: [
                .init(count: model.dueRemaining, label: "повторить", tone: .highlight),
                .init(count: model.newRemaining, label: "новых", tone: .accent),
            ],
            showsCounts: false
        ) {
            DayProgressBar(completed: model.studiedCount, total: max(model.totalCount, 1), tone: .ink)
            Button("Начать") {
                session = StudySessionModel(store: store, catalog: catalog, queue: model.sessionQueue())
            }
            .buttonStyle(PrimaryButtonStyle(.highlight))
            .disabled(!model.hasWork)
        }
    }

    private func message(mark: String, markColor: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(mark)
                .loritoStyle(.display)
                .foregroundStyle(markColor)
                .accessibilityHidden(true)
            Text(title)
                .loritoStyle(.heading)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.lg)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
    }
}

private extension String {
    /// "понедельник, 26 октября" → "Понедельник, 26 октября".
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// Allow presenting the session via `.sheet(item:)`.
extension StudySessionModel: @MainActor Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
