import SwiftUI
import Observation

/// O estado do app, num lugar só.
@MainActor
@Observable
final class Model {
    let awake = Awake()
    var mode: Awake.Mode = Defaults.mode {
        didSet {
            Defaults.mode = mode
            // Trocar o modo com a trava ligada religa na hora, em vez de só
            // valer na próxima vez — senão o menu diz uma coisa e o sistema faz
            // outra.
            if awake.isActive { start(seconds: awake.remaining) }
        }
    }
    var lastError: String?
    /// Toca a cada segundo só enquanto há contagem, para o menu aberto mostrar
    /// o tempo andando sem gastar nada quando está desligado.
    private var ticker: Timer?
    var tick = 0

    init() {
        awake.onChange = { [weak self] in self?.refresh() }
        if Defaults.activateOnLaunch {
            start(seconds: Defaults.lastDuration > 0 ? Defaults.lastDuration : nil)
        }
    }

    var isActive: Bool { awake.isActive }

    /// A linha de estado do topo do menu.
    ///
    /// Com prazo, o que importa é quanto falta; sem prazo, há quanto tempo está
    /// valendo — que é o que responde "isto ainda está de pé?".
    var statusLine: String {
        guard isActive else { return L.t("The Mac can sleep normally") }
        if let restante = awake.remainingLabel {
            return "\(L.t("Awake")) · \(restante) \(L.t("remaining"))"
        }
        return "\(L.t("Awake")) · \(L.t("for")) \(awake.elapsedLabel ?? "0:00")"
    }

    /// A marca da duração em uso, alinhada com as demais.
    func mark(_ duration: Duration) -> String {
        let escolhida = isActive && Defaults.lastDuration == (duration.seconds ?? 0)
        return escolhida ? "✓ " : "   "
    }

    func start(seconds: TimeInterval?) {
        Defaults.lastDuration = seconds ?? 0
        if awake.start(mode: mode, duration: seconds) {
            lastError = nil
        } else {
            lastError = L.t("Could not keep the Mac awake")
        }
        refresh()
    }

    func stop() {
        awake.stop()
        refresh()
    }

    func toggle() {
        isActive ? stop() : start(seconds: Defaults.lastDuration > 0 ? Defaults.lastDuration : nil)
    }

    private func refresh() {
        ticker?.invalidate()
        ticker = nil
        tick += 1

        // Bate de segundo em segundo sempre que está ligado, não só quando há
        // contagem regressiva: sem prazo, o relógio que anda é o de tempo
        // decorrido.
        guard awake.isActive else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick += 1 }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }
}

@main
struct EmberApp: App {
    @State private var model = Model()
    @State private var language = L.shared

    var body: some Scene {
        // A janela Sobre precisa ser uma cena própria para o macOS saber
        // abri-la; `openWindow` a encontra pelo identificador.
        Window(L.t("About Ember"), id: "sobre") {
            AboutView()
                .environment(language)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environment(model)
                .environment(language)
        }

        MenuBarExtra {
            MenuView()
                .environment(model)
                .environment(language)
        } label: {
            // Preenchido quando está segurando, contornado quando não — a
            // diferença tem de se ler de relance, sem cor, porque a barra de
            // menus é monocromática.
            // O raio, e não uma chama: o que o app faz é segurar uma trava de
            // energia, e chama em app de barra de menus lê como Tinder antes
            // de ler como qualquer outra coisa.
            //
            // Formas diferentes, não o mesmo desenho preenchido e vazado: em
            // 16 pixels e sem cor, contorno contra preenchimento quase não se
            // distingue, enquanto o corte do raio se vê de relance.
            Image(systemName: model.isActive ? "bolt.fill" : "bolt.slash")
        }
        // `.menu` e não `.window`: é um menu de verdade, com as teclas e o
        // comportamento que o macOS já dá de graça.
        .menuBarExtraStyle(.menu)
    }
}
