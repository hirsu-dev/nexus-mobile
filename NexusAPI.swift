import Foundation

@MainActor final class NexusStore: ObservableObject {
    @Published var config = NexusConfig()
    @Published var statuses: [ServiceStatus] = [
        .init(name: "NEXUS", online: false, detail: "Checking"),
        .init(name: "Pi-hole", online: false, detail: "Checking"),
        .init(name: "Jellyfin", online: false, detail: "Checking"),
        .init(name: "Tailscale", online: false, detail: "Checking")
    ]
    @Published var messages: [(String, Bool)] = []
    @Published var busy = false
    @Published var nexusOnline = false
    @Published var piholeOnline = false
    @Published var jellyfinOnline = false
    @Published var tailscaleOnline = false

    func refresh() async {
        busy = true; defer { busy = false }
        async let nexusTask = ping(config.baseURL)
        async let piholeTask = ping(config.piHoleURL)
        async let jellyfinTask = ping(config.jellyfinURL)
        let (nexus, pihole, jellyfin) = await (nexusTask, piholeTask, jellyfinTask)
        nexusOnline = nexus; piholeOnline = pihole; jellyfinOnline = jellyfin; tailscaleOnline = nexus
        statuses = [
            .init(name: "NEXUS", online: nexus, detail: nexus ? "Online" : "Offline"),
            .init(name: "Pi-hole", online: pihole, detail: pihole ? "Reachable" : "Offline"),
            .init(name: "Jellyfin", online: jellyfin, detail: jellyfin ? "Reachable" : "Offline"),
            .init(name: "Tailscale", online: nexus, detail: nexus ? "Tailnet link" : "Unavailable")
        ]
    }

    func send(_ text: String, model: String = "qwen3:8b") async {
        guard let url = URL(string: config.baseURL + "/api/chat") else { return }
        messages.append((text, true))
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["model": model, "messages":[["role":"user","content":text]], "stream":false])
        do { let (data, _) = try await URLSession.shared.data(for: request); let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]; let message = (json?["message"] as? [String:Any])?["content"] as? String ?? "No response."; messages.append((message, false)) }
        catch { messages.append(("Connection error: \(error.localizedDescription)", false)) }
    }

    func wakePC() async {
        await postAction("wake-pc")
    }

    func powerOffPC() async { await postAction("shutdown-pc") }

    func tailscaleAction(_ action: String) async { await postAction("tailscale-\(action)") }

    private func postAction(_ type: String) async {
        guard let url = URL(string: config.baseURL + "/api/action") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["type": type])
        _ = try? await URLSession.shared.data(for: request)
    }

    private func ping(_ raw: String) async -> Bool {
        guard let url = URL(string: raw) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode ?? 0 < 500
        } catch {
            return false
        }
    }
}

