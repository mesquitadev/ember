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

        /// Nome curto, para caber ao lado do rótulo do menu.
        var short: String {
            switch self {
            case .display: "tela acesa"
            case .system: "só o sistema"
            }
        }

        /// O tipo de asserção correspondente no IOKit.
        ///
        /// As constantes modernas, e não as antigas `NoDisplaySleep` e
        /// `NoIdleSleep`: aquelas estão obsoletas há anos e hoje funcionam só
        /// por compatibilidade. São também as que o `caffeinate` usa, o que
        /// deixa o comportamento idêntico ao dele em vez de parecido.
        var assertionType: String {
            switch self {
            case .display: kIOPMAssertPreventUserIdleDisplaySleep as String
            case .system: kIOPMAssertPreventUserIdleSystemSleep as String
            }
        }
    }

    private(set) var isActive = false
    private(set) var mode: Mode = .display
    /// Quando a trava se desfaz sozinha. `nil` é indefinido.
    private(set) var endsAt: Date?
    /// Quando começou. Sem limite de tempo, "há quanto tempo" é a única
    /// informação de progresso possível — e é a que responde "isto ainda está
    /// valendo?", que é a pergunta de quem abre o menu para conferir.
    private(set) var startedAt: Date?

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
        startedAt = Date()
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
            startedAt = nil
            onChange?()
        }
    }

    /// Quanto falta, em segundos.
    var remaining: TimeInterval? {
        guard let endsAt else { return nil }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    /// Há quanto tempo está segurando.
    var elapsed: TimeInterval? {
        guard let startedAt else { return nil }
        return Date().timeIntervalSince(startedAt)
    }

    /// Segundos como se leem num relógio.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600, minutes = (total % 3600) / 60, secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    var remainingLabel: String? { remaining.map(Self.clock) }
    var elapsedLabel: String? { elapsed.map(Self.clock) }
}
