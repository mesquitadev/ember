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
    var remainingLabel: String? { awake.remainingLabel }

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

        guard awake.isActive, awake.endsAt != nil else { return }
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
        MenuBarExtra {
            MenuView()
                .environment(model)
                .environment(language)
        } label: {
            // Preenchido quando está segurando, contornado quando não — a
            // diferença tem de se ler de relance, sem cor, porque a barra de
            // menus é monocromática.
            Image(systemName: model.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
        // `.menu` e não `.window`: é um menu de verdade, com as teclas e o
        // comportamento que o macOS já dá de graça.
        .menuBarExtraStyle(.menu)
    }
}
