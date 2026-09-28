import SwiftUI
import ServiceManagement

/// Os ajustes, fora do menu.
///
/// Eles moravam no próprio menu, o que obrigava quem só queria ligar a passar
/// por opções que se configuram uma vez na vida. O menu ficou com a decisão do
/// momento; o que é permanente veio para cá.
struct SettingsView: View {
    @Environment(Model.self) private var model
    @Environment(L.self) private var language

    var body: some View {
        Form {
            Section {
                Toggle(L.t("Open at login"), isOn: Binding(
                    get: { Defaults.opensAtLogin },
                    set: { Defaults.opensAtLogin = $0 }))

                Toggle(L.t("Turn on when Ember opens"), isOn: Binding(
                    get: { Defaults.activateOnLaunch },
                    set: { Defaults.activateOnLaunch = $0 }))
            } header: {
                Text(L.t("Startup"))
            } footer: {
                Text(L.t("With both on, the Mac is protected from the moment you log in."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                // Invertido de propósito: o caso comum — tela acesa — é o
                // padrão e não precisa de explicação. Descrever os dois modos
                // em frases longas foi o que deixou a preferência errada
                // passar despercebida.
                Toggle(L.t("Let the screen turn off"), isOn: Binding(
                    get: { model.mode == .system },
                    set: { model.mode = $0 ? .system : .display }))
            } header: {
                Text(L.t("Behavior"))
            } footer: {
                Text(model.mode == .system
                     ? L.t("The Mac stays awake and the screen sleeps — good for a long build.")
                     : L.t("The screen stays on, like caffeinate -d. This also keeps the Mac awake."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L.t("Language")) {
                Picker(L.t("Language"), selection: Binding(
                    get: { language.language },
                    set: { language.language = $0 })) {
                    ForEach(Language.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A janela Sobre.
struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let curta = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(curta) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(
                    LinearGradient(colors: [Color(red: 0.98, green: 0.69, blue: 0.25),
                                            Color(red: 0.93, green: 0.33, blue: 0.16)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous))

            VStack(spacing: 3) {
                Text("Ember").font(.title2.weight(.semibold))
                Text(L.t("Keeps the Mac awake, from the menu bar"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(version)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }

            Divider().padding(.horizontal, 30)

            // Explica o que o app faz por dentro: quem instala um utilitário
            // que mexe em energia merece saber que não há processo escondido
            // nem nada rodando fora dele.
            Text(L.t("Ember talks to the system power manager directly, the same way caffeinate does. There is no helper process and no background service: the lock is released the moment Ember quits."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26)

            HStack(spacing: 14) {
                Link(L.t("Source code"), destination: URL(string: "https://github.com/mesquitadev/ember")!)
                Link(L.t("Report a problem"), destination: URL(string: "https://github.com/mesquitadev/ember/issues")!)
            }
            .font(.callout)

            Text("Paulo Victor Mesquita · MIT")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 26)
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
    }
}
