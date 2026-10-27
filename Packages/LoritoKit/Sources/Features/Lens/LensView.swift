import SwiftUI
import Domain
import DesignSystem
#if os(iOS)
import PhotosUI
import VisionKit
#endif

/// Grammar Lens: paste, camera or photo → highlighted constructions linked to
/// cards. Card links open the reader when `catalogModel` is given (the app);
/// the Action extension shows results and «Открыть в Lorito» instead.
public struct LensView: View {
    @Bindable var model: LensModel
    let catalogModel: CatalogModel?
    let openInApp: ((String) -> Void)?
    @State private var showCamera = false
    #if os(iOS)
    @State private var photo: PhotosPickerItem?
    #endif
    @State private var inputNote: String?
    @FocusState private var editing: Bool

    public init(model: LensModel, catalogModel: CatalogModel?, openInApp: ((String) -> Void)? = nil) {
        self.model = model
        self.catalogModel = catalogModel
        self.openInApp = openInApp
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                input
                if model.didAnalyze { results }
            }
            .padding(LoritoSpacing.screenGutter)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Разобрать текст")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            LensCameraSheet { text in
                model.text = text
                model.analyze()
            }
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task { await readPhoto(item) }
        }
        #endif
    }

    // MARK: Input

    private var input: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text("Вставьте испанский текст — Lorito подсветит знакомые конструкции и покажет карточки с правилами.")
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $model.text)
                .font(LoritoFont.spanishInline)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(LoritoSpacing.xs)
                .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .focused($editing)
                .accessibilityLabel("Испанский текст")
                .accessibilityIdentifier("lens.text")
            HStack(spacing: LoritoSpacing.sm) {
                Button("Разобрать") {
                    editing = false
                    model.analyze()
                }
                .buttonStyle(PrimaryButtonStyle(.ink))
                .disabled(model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("lens.analyze")
                #if os(iOS)
                Button {
                    if LensCameraSheet.isAvailable { showCamera = true } else { inputNote = LensCameraSheet.unavailableText }
                } label: { Label("Камера", systemImage: "camera") }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                    .accessibilityIdentifier("lens.camera")
                PhotosPicker(selection: $photo, matching: .images) {
                    Label("Фото", systemImage: "photo")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                }
                .accessibilityIdentifier("lens.photo")
                #endif
            }
            .tint(LoritoColor.accent)
            if let inputNote {
                Text(inputNote)
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("lens.inputNote")
            }
        }
    }

    // MARK: Results

    @ViewBuilder
    private var results: some View {
        if model.highlights.isEmpty {
            VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                Text("Знакомых конструкций не нашлось")
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.textPrimary)
                Text("Lorito узнаёт: " + model.coveredTopics.joined(separator: " · "))
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("lens.empty")
        } else {
            Text(highlightedText)
                .font(LoritoFont.spanishInline)
                .foregroundStyle(LoritoColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(LoritoSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .accessibilityIdentifier("lens.highlighted")
            ForEach(model.highlights) { h in highlightRow(h) }
            if let openInApp {
                Button("Открыть в Lorito") { openInApp(model.text) }
                    .buttonStyle(PrimaryButtonStyle(.ink))
            }
        }
    }

    private var highlightedText: AttributedString {
        var out = AttributedString(model.text)
        for h in model.highlights {
            guard let lower = AttributedString.Index(h.range.lowerBound, within: out),
                  let upper = AttributedString.Index(h.range.upperBound, within: out) else { continue }
            out[lower..<upper].backgroundColor = LoritoColor.highlight
            out[lower..<upper].foregroundColor = LoritoColor.ink
        }
        return out
    }

    private func highlightRow(_ h: LensModel.Highlight) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            SpanishText(h.text, size: .inline)
            Text(h.title)
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(h.cards) { card in cardRow(card) }
        }
        .padding(LoritoSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("lens.highlight.\(h.id)")
    }

    @ViewBuilder
    private func cardRow(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
            if let catalogModel {
                NavigationLink {
                    CardReaderView(model: catalogModel, card: card)
                } label: {
                    HStack {
                        Text("\(card.id) · \(card.title)").font(LoritoFont.body).foregroundStyle(LoritoColor.accent)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(LoritoColor.textSecondary).accessibilityHidden(true)
                    }
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("lens.card.\(card.id)")
                let status = model.status(for: card.id)
                if status == .new {
                    Button(LensModel.statusText(.new)) { model.request(card.id) }
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(LoritoColor.accent)
                        .frame(minHeight: LoritoLayout.minTouchTarget)
                        .accessibilityIdentifier("lens.request.\(card.id)")
                } else {
                    Text(LensModel.statusText(status))
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .accessibilityIdentifier("lens.status.\(card.id)")
                }
            } else {
                Text("\(card.id) · \(card.title)").font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
            }
        }
    }

    #if os(iOS)
    /// Live Text from a photo (on device).
    private func readPhoto(_ item: PhotosPickerItem) async {
        defer { photo = nil }
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data),
              ImageAnalyzer.isSupported else {
            inputNote = "Не удалось распознать текст на фото."
            return
        }
        let analysis = try? await ImageAnalyzer().analyze(image, configuration: ImageAnalyzer.Configuration([.text]))
        let text = analysis?.transcript ?? ""
        if text.isEmpty {
            inputNote = "На фото не нашлось текста."
        } else {
            inputNote = nil
            model.text = text
            model.analyze()
        }
    }
    #endif
}

#if os(iOS)
/// Camera Live Text (`DataScannerViewController`, Spanish recognition).
struct LensCameraSheet: View {
    let onText: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recognized = ""

    static var isAvailable: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }
    static let unavailableText = "Камера недоступна. Разрешите доступ: Настройки → Lorito Español → Камера. Вставка текста работает и без неё."

    var body: some View {
        NavigationStack {
            LensScanner(recognized: $recognized)
                .ignoresSafeArea()
                .navigationTitle("Наведите на текст")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Разобрать") { onText(recognized); dismiss() }.disabled(recognized.isEmpty)
                    }
                }
        }
    }
}

private struct LensScanner: UIViewControllerRepresentable {
    @Binding var recognized: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.text(languages: ["es"])], qualityLevel: .accurate,
                                           isHighlightingEnabled: true)
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(recognized: $recognized) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let recognized: Binding<String>
        init(recognized: Binding<String>) { self.recognized = recognized }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            recognized.wrappedValue = allItems.compactMap {
                if case .text(let t) = $0 { return t.transcript } else { return nil }
            }.joined(separator: " ")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            self.dataScanner(dataScanner, didUpdate: addedItems, allItems: allItems)
        }
    }
}
#endif

public extension EnvironmentValues {
    /// Opens Grammar Lens (nil when the bundle has no lens rules).
    @Entry var openLens: (@MainActor (LensSource, String) -> Void)?
}

/// «Разобрать текст» entry used on Today and in the Catalog.
struct LensEntryButton: View {
    let identifier: String
    @Environment(\.openLens) private var openLens

    var body: some View {
        if let openLens {
            Button { openLens(.paste, "") } label: {
                HStack(spacing: LoritoSpacing.sm) {
                    Image(systemName: "text.viewfinder").foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
                    Text("Разобрать текст").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(LoritoColor.textSecondary).accessibilityHidden(true)
                }
                .padding(LoritoSpacing.md)
                .frame(minHeight: LoritoLayout.minTouchTarget)
                .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier)
        }
    }
}
