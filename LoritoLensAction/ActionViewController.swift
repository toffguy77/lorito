import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Domain
import Content
import DesignSystem
import WidgetSupport
import Features

/// «Разобрать в Lorito» (Action extension): analyses shared plain text inside the
/// extension and offers «Открыть в Lorito». The text is never stored.
final class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        CrashReporting.start(.lensAction)
        FontRegistry.registerAll()
        view.backgroundColor = UIColor(LoritoColor.surface)
        Task { @MainActor in show(await sharedText()) }
    }

    private func sharedText() async -> String {
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            if let text = item.attributedContentText?.string, !text.isEmpty { return text }
            for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                    return text
                }
            }
        }
        return ""
    }

    private func show(_ text: String) {
        let catalog: ContentCatalog
        do {
            catalog = try ContentLoader.loadCatalog()
        } catch {
            ErrorReports.report(error, area: .contentLoad)
            close()
            return
        }
        guard let lens = LensModel.bundledCatalog() else {
            close()
            return
        }
        let model = LensModel(store: nil, catalog: catalog, lens: lens, source: .share, text: text,
                              analytics: SilentAnalytics())
        if !text.isEmpty { model.analyze() }
        let root = NavigationStack {
            LensView(model: model, catalogModel: nil, openInApp: { [weak self] text in self?.openInApp(text) })
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Готово") { [weak self] in self?.close() } }
                }
        }
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// Opens the app's Lens with the text (lorito://lens?text=…) via the responder chain.
    private func openInApp(_ text: String) {
        let url = LoritoDeepLink.lens(text: text)
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url)
                break
            }
            responder = r.next
        }
        close()
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

/// The app records lens events (the extension has no consent state of its own).
private final class SilentAnalytics: AnalyticsRecording {
    func record(_ event: AnalyticsEvent) {}
}
