import SwiftUI

/// Progress of one level for the "Мой путь" summary (0…1).
public struct LevelPathProgress: Identifiable, Sendable {
    public let id: String
    public let fraction: Double

    public init(level: String, fraction: Double) {
        self.id = level
        self.fraction = min(max(fraction, 0), 1)
    }
}

/// "Мой путь": a bar per included level.
public struct LevelPathSummary: View {
    private let levels: [LevelPathProgress]

    public init(levels: [LevelPathProgress]) {
        self.levels = levels
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Мой путь")
                .loritoStyle(.label)
                .foregroundStyle(LoritoColor.textSecondary)
            ForEach(levels) { level in
                HStack(spacing: LoritoSpacing.xs) {
                    Text(level.id)
                        .loritoStyle(LoritoTextStyle.heading.sized(13))
                        .frame(minWidth: 28, alignment: .leading)
                    ProgressView(value: level.fraction)
                        .tint(LoritoColor.accent)
                        .background(LoritoColor.surfaceSunken, in: Capsule())
                }
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(level.id): \(Int((level.fraction * 100).rounded())) процентов")
            }
        }
    }
}

/// Sidebar for regular-width layouts (iPadOS 17 fallback; iPadOS 18 uses the
/// system sidebar-adaptable tab view): brand mark, destinations, "Мой путь".
public struct Sidebar<ID: Hashable>: View {
    private let items: [FloatingTabItem<ID>]
    @Binding private var selection: ID
    private let path: [LevelPathProgress]

    public init(items: [FloatingTabItem<ID>], selection: Binding<ID>, path: [LevelPathProgress]) {
        self.items = items
        self._selection = selection
        self.path = path
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            HStack(spacing: LoritoSpacing.xs) {
                Text("¡")
                    .loritoStyle(LoritoTextStyle.heading.sized(22))
                    .foregroundStyle(LoritoColor.highlight)
                    .frame(width: 36, height: 36)
                    .background(LoritoColor.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("Lorito").loritoStyle(.heading).foregroundStyle(LoritoColor.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .padding(.bottom, LoritoSpacing.md)

            ForEach(items) { item in
                let isSelected = item.id == selection
                Button { selection = item.id } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(isSelected ? LoritoColor.onInk : LoritoColor.textPrimary)
                        .padding(.horizontal, LoritoSpacing.sm)
                        .frame(maxWidth: .infinity, minHeight: LoritoLayout.minTouchTarget, alignment: .leading)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous).fill(LoritoColor.ink)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .loritoHover()
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }

            Spacer()
            if !path.isEmpty { LevelPathSummary(levels: path) }
        }
        .padding(LoritoSpacing.md)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(LoritoColor.surfaceRaised)
    }
}

/// Top tab bar for regular width in portrait (iPadOS 17 fallback): the
/// floating capsule, placed at the top.
public struct TopTabBar<ID: Hashable>: View {
    private let items: [FloatingTabItem<ID>]
    @Binding private var selection: ID

    public init(items: [FloatingTabItem<ID>], selection: Binding<ID>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button { selection = item.id } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(isSelected ? LoritoColor.highlight : LoritoColor.textPrimary)
                        .padding(.horizontal, LoritoSpacing.md)
                        .frame(minHeight: LoritoLayout.minTouchTarget)
                        .background {
                            if isSelected { Capsule().fill(LoritoColor.ink) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .loritoHover()
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(LoritoColor.separator))
        .loritoElevation(.tabBar)
    }
}
