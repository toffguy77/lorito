import SwiftUI

/// One destination of the floating tab bar.
public struct FloatingTabItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    public let systemImage: String

    public init(id: ID, title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// A capsule tab bar floating above content. Each destination is an icon
/// button (≥ 44 pt) labeled for VoiceOver; the selected one is an ink pill with
/// a Lima icon.
public struct FloatingTabBar<ID: Hashable>: View {
    private let items: [FloatingTabItem<ID>]
    @Binding private var selection: ID

    public init(items: [FloatingTabItem<ID>], selection: Binding<ID>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button {
                    selection = item.id
                } label: {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(isSelected ? LoritoColor.highlight : LoritoColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: LoritoLayout.tabBarHeight - 12)
                        .background {
                            if isSelected { Capsule().fill(LoritoColor.ink) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .loritoHover()
                .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .frame(height: LoritoLayout.tabBarHeight)
        .background(.regularMaterial, in: Capsule())
        .background(LoritoColor.surfaceRaised.opacity(0.6), in: Capsule())
        .overlay(Capsule().strokeBorder(LoritoColor.separator))
        .loritoElevation(.tabBar)
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}

private struct FloatingTabBarPreview: View {
    @State private var selection = 0

    var body: some View {
        VStack {
            Spacer()
            FloatingTabBar(items: [
                FloatingTabItem(id: 0, title: "Сегодня", systemImage: "sun.max"),
                FloatingTabItem(id: 1, title: "Каталог", systemImage: "point.topleft.down.to.point.bottomright.curvepath"),
                FloatingTabItem(id: 2, title: "Прогресс", systemImage: "flame"),
                FloatingTabItem(id: 3, title: "Настройки", systemImage: "slider.horizontal.3"),
            ], selection: $selection)
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
        .background(LoritoColor.surface)
    }
}

#Preview {
    FloatingTabBarPreview()
}
