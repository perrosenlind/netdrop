import SwiftUI

struct MultiDestinationView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFavoriteIDs: Set<UUID> = []
    @State private var localPaths: [String] = []
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "arrow.up.to.line.compact")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Upload to Multiple Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            HStack(spacing: 0) {
                // Left: file selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files")
                        .font(.headline)

                    if localPaths.isEmpty {
                        ContentUnavailableView {
                            Label("No Files", systemImage: "doc")
                        } description: {
                            Text("Add files to upload.")
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(localPaths, id: \.self) { path in
                                HStack {
                                    Image(systemName: "doc")
                                    Text((path as NSString).lastPathComponent)
                                    Spacer()
                                    Text((path as NSString).deletingLastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .onDelete { offsets in
                                localPaths.remove(atOffsets: offsets)
                            }
                        }
                        .listStyle(.inset)
                    }

                    Button("Add Files…") {
                        showingFilePicker = true
                    }
                }
                .padding()
                .frame(minWidth: 250)

                Divider()

                // Right: destination selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destinations")
                        .font(.headline)

                    if favoritesStore.favorites.isEmpty {
                        ContentUnavailableView {
                            Label("No Favorites", systemImage: "star")
                        } description: {
                            Text("Add favorites first.")
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List(selection: $selectedFavoriteIDs) {
                            ForEach(favoritesStore.groups, id: \.self) { group in
                                Section(group) {
                                    ForEach(favoritesStore.favorites(inGroup: group)) { fav in
                                        FavoriteRow(favorite: fav)
                                            .tag(fav.id)
                                    }
                                }
                            }
                            if !favoritesStore.ungrouped.isEmpty {
                                Section(favoritesStore.groups.isEmpty ? "Favorites" : "Ungrouped") {
                                    ForEach(favoritesStore.ungrouped) { fav in
                                        FavoriteRow(favorite: fav)
                                            .tag(fav.id)
                                    }
                                }
                            }
                        }
                        .listStyle(.inset)
                    }

                    HStack {
                        Button("Select All") {
                            selectedFavoriteIDs = Set(favoritesStore.favorites.map(\.id))
                        }
                        Button("Clear") {
                            selectedFavoriteIDs.removeAll()
                        }
                    }
                }
                .padding()
                .frame(minWidth: 250)
            }

            Divider()

            HStack {
                Text("\(localPaths.count) file(s) → \(selectedFavoriteIDs.count) device(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Upload All") { startMultiUpload() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(localPaths.isEmpty || selectedFavoriteIDs.isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 450)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                let newPaths = urls.map(\.path)
                for path in newPaths where !localPaths.contains(path) {
                    localPaths.append(path)
                }
            }
        }
    }

    private func startMultiUpload() {
        let selectedFavorites = favoritesStore.favorites.filter { selectedFavoriteIDs.contains($0.id) }
        transferManager.uploadToMultipleDestinations(localPaths: localPaths, favorites: selectedFavorites)
        dismiss()
    }
}
