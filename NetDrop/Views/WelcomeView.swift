import SwiftUI

struct WelcomeView: View {
    @Binding var showingAddFavorite: Bool
    @Binding var showingQuickConnect: Bool
    @Binding var showingMultiDestination: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and title
            VStack(spacing: 12) {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                Text("NetDrop")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Secure file transfers for network devices")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Quick action cards
            HStack(spacing: 16) {
                ActionCard(
                    icon: "plus.circle.fill",
                    color: .blue,
                    title: "Add Device",
                    subtitle: "Save a connection",
                    shortcut: "Cmd+N"
                ) {
                    showingAddFavorite = true
                }

                ActionCard(
                    icon: "bolt.fill",
                    color: .orange,
                    title: "Quick Connect",
                    subtitle: "One-time connection",
                    shortcut: "Cmd+K"
                ) {
                    showingQuickConnect = true
                }

                ActionCard(
                    icon: "square.and.arrow.up.on.square",
                    color: .purple,
                    title: "Multi-Upload",
                    subtitle: "Send to many devices",
                    shortcut: "Cmd+Shift+M"
                ) {
                    showingMultiDestination = true
                }
            }
            .padding(.horizontal, 40)

            // Keyboard shortcuts reference
            VStack(spacing: 8) {
                Text("Keyboard Shortcuts")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 20) {
                    ShortcutHint(keys: "Cmd+N", label: "New Device")
                    ShortcutHint(keys: "Cmd+K", label: "Quick Connect")
                    ShortcutHint(keys: "Cmd+U", label: "Upload")
                    ShortcutHint(keys: "Cmd+Shift+M", label: "Multi-Upload")
                    ShortcutHint(keys: "Cmd+,", label: "Settings")
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ActionCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(shortcut)
                    .font(.system(.caption2, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct ShortcutHint: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(.system(.caption2, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
