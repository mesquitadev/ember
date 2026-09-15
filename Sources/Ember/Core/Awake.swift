import Foundation
import IOKit.pwr_mgt

/// Mantém o Mac acordado.
///
/// Não chama o `caffeinate`. Aquele utilitário é um invólucro fino sobre esta
/// mesma API do sistema, e delegar a ele custaria caro: um processo filho que
/// sobrevive se o app morrer de repente, nenhuma forma de saber quanto tempo
/// falta, e cancelamento que depende de matar um PID. Falando direto com o
/// gerenciamento de energia, a trava morre junto com o app — inclusive se ele
/// for encerrado à força, porque o sistema descarta asserções de processos que
/// não existem mais.
@MainActor
final class Awake {
    /// O que exatamente fica impedido de dormir.
    enum Mode: String, CaseIterable, Identifiable, Sendable {
        /// Tela acesa. É o `caffeinate -d`, e o caso comum: apresentação,
        /// leitura, acompanhar algo rodando.
        case display
        /// Sistema acordado, mas a tela pode apagar. É o `caffeinate -i`, para
        /// um build longo ou um download sem ninguém olhando.
        case system

        var id: String { rawValue }

        var title: String {
            switch self {
            case .display: "Keep the display on"
            case .system: "Keep the Mac awake, screen may sleep"
            }
        }

        /// O tipo de asserção correspondente no IOKit.
        var assertionType: String {
            switch self {
            case .display: kIOPMAssertionTypeNoDisplaySleep as String
            case .system: kIOPMAssertionTypeNoIdleSleep as String
            }
        }
    }

    private(set) var isActive = false
    private(set) var mode: Mode = .display
    /// Quando a trava se desfaz sozinha. `nil` é indefinido.
    private(set) var endsAt: Date?

    private var assertion: IOPMAssertionID = IOPMAssertionID(0)
    private var timer: Timer?
    /// Avisa a interface que algo mudou — inclusive quando o tempo acaba
    /// sozinho, que é a mudança que ninguém pediu e precisa aparecer.
    var onChange: (() -> Void)?

    /// Liga a trava. `duration` em segundos; `nil` mantém até alguém desligar.
    @discardableResult
    func start(mode: Mode, duration: TimeInterval?) -> Bool {
        stop()

        var id = IOPMAssertionID(0)
        // O motivo aparece em `pmset -g assertions`, e é o que explica para
        // quem investiga por que a máquina não dormiu.
        let reason = "Ember: \(mode.title)" as CFString
        let result = IOPMAssertionCreateWithName(
            mode.assertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &id)

        guard result == kIOReturnSuccess else { return false }

        assertion = id
        isActive = true
        self.mode = mode
        endsAt = duration.map { Date().addingTimeInterval($0) }

        if let duration {
            let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
            // `.common` para o prazo continuar correndo enquanto o menu está
            // aberto: um menu aberto bloqueia o modo padrão do run loop.
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }

        onChange?()
        return true
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        if isActive {
            IOPMAssertionRelease(assertion)
            assertion = IOPMAssertionID(0)
            isActive = false
            endsAt = nil
            onChange?()
        }
    }

    /// Quanto falta, em segundos.
    var remaining: TimeInterval? {
        guard let endsAt else { return nil }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    /// O tempo restante como se lê num relógio.
    var remainingLabel: String? {
        guard let remaining else { return nil }
        let total = Int(remaining.rounded())
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }
}
