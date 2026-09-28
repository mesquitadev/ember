import SwiftUI

/// O menu: só a decisão do momento.
///
/// Ele já teve as preferências dentro, o que obrigava quem só queria ligar a
/// passar por opções que se configuram uma vez na vida. O permanente foi para
/// os Ajustes; aqui ficou o estado, o liga-desliga e por quanto tempo.
struct MenuView: View {
    @Environment(Model.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        // Ler `model.tick` aqui é o que faz o relógio andar com o menu aberto.
        let _ = model.tick

        // O estado vem primeiro: quem abre o menu quer saber se está valendo e
        // há quanto tempo, antes de qualquer opção.
        Text(model.statusLine)

        if model.isActive {
            Button(L.t("Turn off"), action: model.stop)
                .keyboardShortcut("k")
        }

        Divider()

        // As durações no nível principal, e escolher uma já liga. Antes eram
        // um submenu separado do liga-desliga, o que fazia parecer que havia
        // duas decisões quando sempre houve uma.
        Text(L.t("Keep awake for"))
        ForEach(Duration.allCases) { duration in
            Button(model.mark(duration) + L.t(duration.label)) {
                model.start(seconds: duration.seconds)
            }
        }

        Divider()

        Button(L.t("Settings…")) { openSettings() }
            .keyboardShortcut(",")
        Button(L.t("About Ember")) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "sobre")
        }

        Divider()
        Button(L.t("Quit Ember")) { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
