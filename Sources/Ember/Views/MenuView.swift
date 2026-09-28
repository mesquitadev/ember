import SwiftUI

struct MenuView: View {
    @Environment(Model.self) private var model
    @Environment(L.self) private var language

    var body: some View {
        // Ler `model.tick` aqui é o que faz o tempo restante se redesenhar a
        // cada segundo enquanto o menu está aberto.
        let _ = model.tick

        Button(action: model.toggle) {
            if model.isActive, let remaining = model.remainingLabel {
                Text("\(L.t("Awake")) · \(remaining) \(L.t("remaining"))")
            } else if model.isActive {
                Text(L.t("The Mac will not sleep"))
            } else {
                Text(L.t("The Mac can sleep normally"))
            }
        }
        .keyboardShortcut("k")

        if model.isActive {
            Button(L.t("Turn off"), action: model.stop)
        }

        if let error = model.lastError {
            Divider()
            Text(error)
        }

        Divider()

        Menu(L.t("Keep awake for")) {
            ForEach(Duration.allCases) { duration in
                Button(L.t(duration.label)) { model.start(seconds: duration.seconds) }
            }
        }

        // O modo ativo é escrito no rótulo do próprio menu, não só dentro
        // dele: quem abre para conferir em que modo está não devia precisar
        // navegar mais um nível para descobrir.
        Menu("\(L.t("Mode")): \(L.t(model.mode.short))") {
            ForEach(Awake.Mode.allCases) { mode in
                // Marca explícita em vez de Toggle: o Toggle dentro de menu
                // deixou de mostrar estado, e um menu de escolha sem indicar a
                // escolha atual é como esta preferência virou a errada sem
                // ninguém notar.
                Button("\(model.mode == mode ? "✓ " : "   ")\(L.t(mode.title))") {
                    model.mode = mode
                }
            }
        }

        Divider()

        Toggle(L.t("Open at login"), isOn: Binding(
            get: { Defaults.opensAtLogin },
            set: { Defaults.opensAtLogin = $0 }))

        Toggle(L.t("Turn on when Ember opens"), isOn: Binding(
            get: { Defaults.activateOnLaunch },
            set: { Defaults.activateOnLaunch = $0 }))

        Menu(L.t("Language")) {
            ForEach(Language.allCases) { option in
                Toggle(option.label, isOn: Binding(
                    get: { language.language == option },
                    set: { if $0 { language.language = option } }))
            }
        }

        Divider()
        Button(L.t("Quit Ember")) { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
