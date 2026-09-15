import Foundation
import Observation

/// Idiomas que o app fala. Inglês é o padrão; a preferência do sistema só é
/// seguida quando o usuário não escolheu explicitamente.
enum Language: String, CaseIterable, Identifiable, Sendable {
    case system, en, ptBR = "pt-BR"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .en: "English"
        case .ptBR: "Português (Brasil)"
        }
    }

    var resolved: Language {
        guard self == .system else { return self }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("pt") ? .ptBR : .en
    }
}

/// O tradutor. A chave é o próprio texto em inglês, então uma entrada que falte
/// aparece em inglês — nunca como identificador cru.
@MainActor
@Observable
final class L {
    static let shared = L()

    var language: Language = Language(rawValue: UserDefaults.standard.string(forKey: "language") ?? "") ?? .system {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language") }
    }

    static func t(_ key: String) -> String {
        guard shared.language.resolved == .ptBR else { return key }
        return ptBR[key] ?? key
    }
}
