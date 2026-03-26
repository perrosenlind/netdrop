import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings

        Form {
            Section("Appearance") {
                Picker("Theme", selection: $s.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Label(mode.label, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 150)
    }
}
