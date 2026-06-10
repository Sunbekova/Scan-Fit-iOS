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

final class LanguageManager: ObservableObject {

    static let shared = LanguageManager()

    private let key = "app_language"

    @Published private(set) var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: key)
            updateBundle()
        }
    }

    private(set) var bundle: Bundle = .main

    private init() {
        // If user has previously chosen a language, use it.
        // Otherwise, detect from iPhone system language settings.
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            current = lang
        } else {
            // Auto-detect from device preferred languages
            let preferred = Locale.preferredLanguages.first ?? "en"
            let code = String(preferred.prefix(2)).lowercased()
            if code == "ru" {
                current = .russian
            } else if code == "kk" {
                current = .kazakh
            } else {
                current = .english
            }
        }
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
    var localized: String {
        LanguageManager.shared.bundle.localizedString(forKey: self, value: self, table: nil)
    }
}

// MARK: - View modifier to force UI refresh on language change

struct LanguageAwareModifier: ViewModifier {
    @ObservedObject var lm = LanguageManager.shared
    func body(content: Content) -> some View {
        content.id(lm.current)
    }
}

extension View {
    func languageAware() -> some View {
        modifier(LanguageAwareModifier())
    }
}
