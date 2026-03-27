import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var showingFolderPicker = false

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

            Section("Backups") {
                HStack {
                    Text("Config backup directory")
                    Spacer()
                    Text(abbreviatePath(settings.backupDirectory))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                HStack {
                    Button("Choose…") {
                        showingFolderPicker = true
                    }
                    Button("Reset to Default") {
                        settings.backupDirectory = AppSettings.defaultBackupDirectory
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 250)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                settings.backupDirectory = url.path
            }
        }
    }

    private func abbreviatePath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}
