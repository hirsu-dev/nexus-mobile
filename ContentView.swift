import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NexusStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AITab().tabItem { Label("NEXUS AI", systemImage: "sparkles") }.tag(0)
            TailscaleTab().tabItem { Label("Tailscale", systemImage: "network") }.tag(1)
            JellyfinTab().tabItem { Label("Jellyfin", systemImage: "play.tv") }.tag(2)
            PiHoleTab().tabItem { Label("Pi-hole", systemImage: "shield.lefthalf.filled") }.tag(3)
            PowerTab().tabItem { Label("PC Power", systemImage: "power") }.tag(4)
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }
}

private struct Shell<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    @EnvironmentObject var store: NexusStore

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NEXUS").font(.system(size: 14, weight: .bold, design: .rounded)).tracking(4).foregroundStyle(.cyan)
                    Text(title).font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(subtitle).foregroundStyle(.secondary)
                }
                content
            }.padding() }
            .background(LinearGradient(colors: [.black, Color(red: 0.02, green: 0.07, blue: 0.13)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { SettingsView().environmentObject(store) } label: { Image(systemName: "gearshape.fill") } } }
        }
    }
}

private struct AITab: View {
    @EnvironmentObject var store: NexusStore
    @State private var prompt = ""
    @State private var model = "qwen3:8b"
    private let models = ["qwen3:8b", "llama3.1:8b", "llama3-alpha-centauri"]

    var body: some View {
        Shell(title: "Personal command center", subtitle: "Ask NEXUS, check your services, and control your home stack.") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("LOCAL AI", systemImage: "circle.fill").foregroundStyle(.green)
                    Spacer()
                    Picker("Model", selection: $model) { ForEach(models, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                }
                ForEach(Array(store.messages.enumerated()), id: \.offset) { _, message in
                    Text(message.0).padding(12).frame(maxWidth: .infinity, alignment: message.1 ? .trailing : .leading)
                        .background(message.1 ? Color.blue.opacity(0.35) : Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                }
                HStack(alignment: .bottom) {
                    TextField("Ask NEXUS…", text: $prompt, axis: .vertical).lineLimit(1...5).textFieldStyle(.roundedBorder)
                    Button { let value = prompt; prompt = ""; Task { await store.send(value, model: model) } } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }.disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.padding().background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
        }
    }
}

private struct TailscaleTab: View {
    @EnvironmentObject var store: NexusStore
    var body: some View {
        Shell(title: "Tailscale", subtitle: "Keep NEXUS reachable when you leave home.") {
            StatusCard(name: "Tailnet link", online: store.tailscaleOnline, detail: store.tailscaleOnline ? "Connected" : "Disconnected")
            HStack {
                Button("Connect") { Task { await store.tailscaleAction("connect") } }.buttonStyle(.borderedProminent)
                Button("Disconnect") { Task { await store.tailscaleAction("disconnect") } }.buttonStyle(.bordered)
                Button("Refresh") { Task { await store.refresh() } }.buttonStyle(.bordered)
            }
            Text("The PC-side NEXUS service must expose the Tailscale action endpoint for these buttons to operate.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct JellyfinTab: View {
    @EnvironmentObject var store: NexusStore
    @Environment(\.openURL) private var openURL
    var body: some View {
        Shell(title: "Jellyfin", subtitle: "Your personal media library.") {
            StatusCard(name: "Jellyfin", online: store.jellyfinOnline, detail: store.jellyfinOnline ? "Online" : "Offline")
            Button("Open Jellyfin") { if let url = URL(string: store.config.jellyfinURL) { openURL(url) } }.buttonStyle(.borderedProminent)
            Button("Refresh status") { Task { await store.refresh() } }.buttonStyle(.bordered)
        }
    }
}

private struct PiHoleTab: View {
    @EnvironmentObject var store: NexusStore
    @Environment(\.openURL) private var openURL
    var body: some View {
        Shell(title: "Pi-hole", subtitle: "DNS filtering and network protection.") {
            StatusCard(name: "Pi-hole", online: store.piholeOnline, detail: store.piholeOnline ? "Reachable" : "Offline")
            Button("Open Pi-hole dashboard") { if let url = URL(string: store.config.piHoleURL) { openURL(url) } }.buttonStyle(.borderedProminent)
            Button("Refresh status") { Task { await store.refresh() } }.buttonStyle(.bordered)
        }
    }
}

private struct PowerTab: View {
    @EnvironmentObject var store: NexusStore
    @State private var message = ""
    var body: some View {
        Shell(title: "PC power", subtitle: "Wake or shut down your computer remotely.") {
            StatusCard(name: "PC relay", online: store.nexusOnline, detail: store.nexusOnline ? "Reachable" : "Offline")
            HStack {
                Button("Wake PC") { Task { await store.wakePC(); message = "Wake request sent." } }.buttonStyle(.borderedProminent)
                Button("Shut down") { Task { await store.powerOffPC(); message = "Shutdown request sent." } }.buttonStyle(.bordered).tint(.red)
            }
            if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary) }
            Text("Shutdown requires the PC-side relay to explicitly allow the action.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct StatusCard: View {
    let name: String
    let online: Bool
    let detail: String
    var body: some View { HStack(spacing: 14) { Image(systemName: online ? "checkmark.circle.fill" : "xmark.circle.fill").font(.title2).foregroundStyle(online ? .green : .red); VStack(alignment: .leading) { Text(name).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) }; Spacer() }.padding().background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18)) }
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
                Text("Use Tailscale hostnames or tailnet IPs when away from home Wi‑Fi.").font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}


