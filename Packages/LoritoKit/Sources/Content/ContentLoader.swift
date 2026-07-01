import Foundation
import Domain

/// Loads the compiled content artifact (content.json) embedded in this module's bundle.
public enum ContentLoader {
    public enum LoadError: Error {
        case missingResource
    }

    /// Decode the full catalog from the bundled `content.json`.
    public static func loadCatalog() throws -> ContentCatalog {
        guard let url = Bundle.module.url(forResource: "content", withExtension: "json") else {
            throw LoadError.missingResource
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ContentCatalog.self, from: data)
    }

    /// The URL of a bundled picture-matching image asset (nil if not present).
    public static func exerciseAssetURL(_ name: String) -> URL? {
        let stem = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        return Bundle.module.url(
            forResource: stem,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: "exercise-assets"
        )
    }
}
