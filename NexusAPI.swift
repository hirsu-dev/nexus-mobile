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

    func refresh() async {
        busy = true; defer { busy = false }
        let nexus = await ping(config.baseURL)
        let pihole = await ping(config.piHoleURL)
        let jellyfin = await ping(config.jellyfinURL)
        statuses = [
            .init(name: "NEXUS", online: nexus, detail: nexus ? "Online" : "Offline"),
            .init(name: "Pi-hole", online: pihole, detail: pihole ? "Reachable" : "Offline"),
            .init(name: "Jellyfin", online: jellyfin, detail: jellyfin ? "Reachable" : "Offline"),
            .init(name: "Tailscale", online: nexus, detail: nexus ? "Tailnet link" : "Unavailable")
        ]
    }

    func send(_ text: String) async {
        guard let url = URL(string: config.baseURL + "/api/chat") else { return }
        messages.append((text, true))
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["model":"qwen3:8b", "messages":[["role":"user","content":text]], "stream":false])
        do { let (data, _) = try await URLSession.shared.data(for: request); let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]; let message = (json?["message"] as? [String:Any])?["content"] as? String ?? "No response."; messages.append((message, false)) }
        catch { messages.append(("Connection error: \(error.localizedDescription)", false)) }
    }

    func wakePC() async {
        guard let url = URL(string: config.baseURL + "/api/action") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try? JSONSerialization.data(withJSONObject: ["type":"wake-pc"])
        _ = try? await URLSession.shared.data(for: request)
    }

    private func ping(_ raw: String) async -> Bool { guard let url = URL(string: raw) else { return false }; do { let (_, response) = try await URLSession.shared.data(from: url); return (response as? HTTPURLResponse)?.statusCode ?? 0 < 500 } catch { return false } }
}
