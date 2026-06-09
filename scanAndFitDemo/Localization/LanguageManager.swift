import Foundation
import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case kazakh = "kk"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .kazakh: return "Қазақша"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .russian: return "🇷🇺"
        case .kazakh: return "🇰🇿"
        }
    }
}

//LanguageManager

final class LanguageManager: ObservableObject {

    static let shared = LanguageManager()

    private let key = "app_language"

    @Published private(set) var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: key)
            updateBundle()
        }
    }

    /// The bundle that contains the active language's .strings file
    private(set) var bundle: Bundle = .main

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? ""
        current = AppLanguage(rawValue: saved) ?? .english
        updateBundle()
    }

    func set(_ language: AppLanguage) {
        guard language != current else { return }
        current = language
    }

    private func updateBundle() {
        guard
            let path = Bundle.main.path(forResource: current.rawValue, ofType: "lproj"),
            let b    = Bundle(path: path)
        else {
            bundle = .main
            return
        }
        bundle = b
    }
}

// MARK: - String extension

extension String {
    /// Returns a localized string using the currently active LanguageManager bundle.
    var localized: String {
        LanguageManager.shared.bundle.localizedString(forKey: self, value: self, table: nil)
    }

    /// Localized with printf-style format arguments.
    func localized(_ args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}

// MARK: - View modifier to force UI refresh on language change

struct LanguageAwareModifier: ViewModifier {
    @ObservedObject var lm = LanguageManager.shared

    func body(content: Content) -> some View {
        content
            // Changing the ID forces SwiftUI to rebuild the entire tree
            .id(lm.current.rawValue)
    }
}

extension View {
    /// Apply this once at the root view to make the whole app react to language changes.
    func languageAware() -> some View {
        modifier(LanguageAwareModifier())
    }
}
