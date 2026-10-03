import Foundation

struct ServiceStatus: Codable, Identifiable {
    var id: String { name }
    let name: String
    var online: Bool
    var detail: String
}

struct NexusConfig: Codable {
    var baseURL = "https://desktop-mdk19q5.tail5cb586.ts.net"
    var piHoleURL = "http://192.168.68.2/admin"
    var jellyfinURL = "http://192.168.68.2:8096"
}
