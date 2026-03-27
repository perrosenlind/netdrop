import SwiftUI

struct PasswordPromptView: View {
    @Environment(\.dismiss) private var dismiss

    let favoriteName: String
    @Binding var password: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text("Password Required")
                    .font(.headline)

                Text("Enter the password for \(favoriteName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                    .onSubmit { submit() }

                Text("Will be saved to macOS Keychain")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()

            Divider()

            HStack {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Connect") { submit() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(password.isEmpty)
            }
            .padding()
        }
        .frame(width: 320)
    }

    private func submit() {
        onSubmit()
        dismiss()
    }
}
