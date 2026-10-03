import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NexusStore
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    serviceGrid

                    HStack(spacing: 10) {
                        Button("Wake PC") {
                            Task { await store.wakePC() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Refresh") {
                            Task { await store.refresh() }
                        }
                        .buttonStyle(.bordered)
                    }

                    chat
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.black, Color(red: 0.03, green: 0.08, blue: 0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("NEXUS")
            .toolbar {
                NavigationLink("Settings") {
                    SettingsView().environmentObject(store)
                }
            }
        }
        .task { await store.refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PERSONAL COMMAND CENTER")
                .font(.caption)
                .tracking(3)
                .foregroundStyle(.cyan)
            Text("Welcome back.")
                .font(.largeTitle.bold())
            Text("Your PC, Pi-hole, Jellyfin, Tailscale, and local AI in one place.")
                .foregroundStyle(.secondary)
        }
    }

    private var serviceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(store.statuses) { status in
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        status.name,
                        systemImage: status.online ? "checkmark.circle.fill" : "xmark.circle"
                    )
                    .foregroundStyle(status.online ? Color.green : Color.red)

                    Text(status.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var chat: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEXUS AI")
                .font(.headline)
                .foregroundStyle(.cyan)

            ForEach(Array(store.messages.enumerated()), id: \.offset) { _, message in
                Text(message.0)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: message.1 ? .trailing : .leading)
                    .background(
                        message.1 ? Color.blue.opacity(0.35) : Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }

            HStack {
                TextField("Ask NEXUS…", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    let text = prompt
                    prompt = ""
                    Task { await store.send(text) }
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: NexusStore

    var body: some View {
        Form {
            Section("Connections") {
                TextField("NEXUS URL", text: $store.config.baseURL)
                TextField("Pi-hole URL", text: $store.config.piHoleURL)
                TextField("Jellyfin URL", text: $store.config.jellyfinURL)
            }

            Section {
                Text("Credentials will be stored in the iOS Keychain in the signed build.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}
