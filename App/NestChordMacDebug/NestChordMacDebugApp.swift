import PluginUI
import SwiftUI

@main
struct NestChordMacDebugApp: App {
    @StateObject private var store = PatternStore()
    @StateObject private var midiOutput = CoreMIDIOutputManager()

    var body: some Scene {
        WindowGroup {
            MacDebugRootView(store: store, midiOutput: midiOutput)
                .frame(minWidth: 980, minHeight: 680)
                .onAppear {
                    store.midiOutputSink = midiOutput
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}

private struct MacDebugRootView: View {
    @ObservedObject var store: PatternStore
    @ObservedObject var midiOutput: CoreMIDIOutputManager

    var body: some View {
        VStack(spacing: 0) {
            midiToolbar
            Divider()
                .overlay(Color.white.opacity(0.08))
            NestChordEditorView(store: store, showsLocalTransport: true)
        }
        .background(Color(red: 0.055, green: 0.06, blue: 0.07))
    }

    private var midiToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("macOS MIDI Debug")
                    .font(.headline)
                Text(midiOutput.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("Virtual Source: NestChord Debug Source") {
                    midiOutput.useVirtualSource()
                }

                if !midiOutput.destinations.isEmpty {
                    Divider()
                }

                ForEach(midiOutput.destinations) { destination in
                    Button(destination.name) {
                        midiOutput.selectDestination(destination)
                    }
                }
            } label: {
                Label(midiOutput.selectedDestinationName, systemImage: "cable.connector")
                    .lineLimit(1)
                    .frame(minWidth: 230, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Button {
                midiOutput.refreshDestinations()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .help("Refresh MIDI destinations")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.088, blue: 0.10))
    }
}
