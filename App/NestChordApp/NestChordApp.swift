import PluginUI
import SwiftUI

@main
struct NestChordApp: App {
    @StateObject private var store = PatternStore()

    var body: some Scene {
        WindowGroup {
            NestChordEditorView(store: store, showsLocalTransport: true)
        }
    }
}
