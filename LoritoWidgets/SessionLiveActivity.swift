import SwiftUI
import WidgetKit
import ActivityKit
import Domain
import DesignSystem
import WidgetSupport

/// The running study session in the Dynamic Island and on the Lock Screen.
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            lockScreen(context.state)
                .padding(16)
                .activityBackgroundTint(LoritoColor.ink)
                .activitySystemActionForegroundColor(LoritoColor.highlight)
                .widgetURL(LoritoDeepLink.today)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("¡L").font(LoritoTextStyle.heading.sized(18).font).foregroundStyle(LoritoColor.highlight)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.position) / \(context.state.total)")
                        .font(LoritoFont.bodyStrong).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: Double(context.state.position), total: Double(max(context.state.total, 1)))
                            .tint(LoritoColor.highlight)
                        Text(minutesText(context.state)).font(LoritoFont.caption)
                    }
                }
            } compactLeading: {
                Text("¡L").font(LoritoTextStyle.heading.sized(14).font).foregroundStyle(LoritoColor.highlight)
            } compactTrailing: {
                Text("\(context.state.position)/\(context.state.total)").font(LoritoFont.caption).monospacedDigit()
            } minimal: {
                Text("\(context.state.position)").font(LoritoFont.caption).foregroundStyle(LoritoColor.highlight)
            }
            .widgetURL(LoritoDeepLink.today)
            .keylineTint(LoritoColor.highlight)
        }
    }

    private func lockScreen(_ state: SessionActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Сессия идёт").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.onInk)
                Spacer()
                Text("\(state.position) / \(state.total)")
                    .font(LoritoFont.bodyStrong).monospacedDigit().foregroundStyle(LoritoColor.highlight)
            }
            ProgressView(value: Double(state.position), total: Double(max(state.total, 1)))
                .tint(LoritoColor.highlight)
            Text(minutesText(state)).font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
        }
    }

    private func minutesText(_ state: SessionActivityAttributes.ContentState) -> String {
        state.minutesLeft > 0 ? "≈ \(state.minutesLeft) мин осталось" : "Готово"
    }
}
