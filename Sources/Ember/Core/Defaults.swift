import Foundation
import ServiceManagement

enum Defaults {
    private static let store = UserDefaults.standard

    /// O modo escolhido da última vez — quem usa para apresentação quer tela
    /// acesa sempre, quem usa para build quer o outro sempre.
    static var mode: Awake.Mode {
        get { Awake.Mode(rawValue: store.string(forKey: "mode") ?? "") ?? .display }
        set { store.set(newValue.rawValue, forKey: "mode") }
    }

    /// Ligar assim que o app abre. Para quem quer isso permanentemente ligado,
    /// junto com abrir no login, o app desaparece de vez do caminho.
    static var activateOnLaunch: Bool {
        get { store.bool(forKey: "activateOnLaunch") }
        set { store.set(newValue, forKey: "activateOnLaunch") }
    }

    /// A última duração escolhida, em segundos; 0 é indefinido.
    static var lastDuration: TimeInterval {
        get { store.double(forKey: "lastDuration") }
        set { store.set(newValue, forKey: "lastDuration") }
    }

    /// Abrir junto com o sistema, pelo registro moderno do macOS — sem mexer em
    /// LaunchAgents na mão, que é o que quebra a cada atualização.
    static var opensAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Ember: não consegui mudar a abertura no login — \(error)")
            }
        }
    }
}

/// As opções de tempo do menu.
enum Duration: CaseIterable, Identifiable {
    case indefinite, minutes15, minutes30, hour1, hours2, hours4, hours8

    var id: String { label }

    var seconds: TimeInterval? {
        switch self {
        case .indefinite: nil
        case .minutes15: 15 * 60
        case .minutes30: 30 * 60
        case .hour1: 3600
        case .hours2: 2 * 3600
        case .hours4: 4 * 3600
        // Oito horas cobre um dia de trabalho inteiro sem virar "para sempre".
        case .hours8: 8 * 3600
        }
    }

    var label: String {
        switch self {
        case .indefinite: "Until I turn it off"
        case .minutes15: "15 minutes"
        case .minutes30: "30 minutes"
        case .hour1: "1 hour"
        case .hours2: "2 hours"
        case .hours4: "4 hours"
        case .hours8: "8 hours"
        }
    }
}
