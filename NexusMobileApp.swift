import SwiftUI

@main
struct NexusMobileApp: App {
    @StateObject private var store = NexusStore()
    var body: some Scene { WindowGroup { ContentView().environmentObject(store) } }
}
