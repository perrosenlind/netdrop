import SwiftUI

struct SaveFavoriteView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss

    let favorite: Favorite
    @Binding var name: String
    @Binding var group: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "star.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)

                Text("Save as Favorite")
                    .font(.headline)

                Text("\(favorite.username)@\(favorite.host):\(favorite.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Form {
                TextField("Name", text: $name, prompt: Text(favorite.host))
                TextField("Folder", text: $group, prompt: Text("Optional"))
                if !favoritesStore.groups.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(favoritesStore.groups, id: \.self) { g in
                            Button(g) { group = g }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 320)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 320)
    }
}
