import SwiftUI

public struct NestChordEditorView: View {
    @ObservedObject private var store: PatternStore
    private let showsLocalTransport: Bool

    public init(store: PatternStore, showsLocalTransport: Bool = false) {
        self.store = store
        self.showsLocalTransport = showsLocalTransport
    }

    public var body: some View {
        ZStack {
            NestChordTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: NestChordTheme.sectionSpacing) {
                    PatternHeader(store: store)

                    if showsLocalTransport {
                        TransportStrip(store: store)
                    }

                    ChordBlockTimeline(store: store)
                    selectedBlockInspector
                    DebugStatusPanel(store: store, showsLocalControls: showsLocalTransport)
                }
                .padding(NestChordTheme.outerPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var selectedBlockInspector: some View {
        if let index = store.selectedBlockIndex {
            BlockInspector(
                block: $store.pattern.blocks[index],
                pattern: store.pattern,
                onDurationPreset: { duration in
                    store.setBlockDuration(id: store.pattern.blocks[index].id, duration: duration)
                },
                onAudition: store.auditionSelectedBlock,
                onDuplicate: {
                    store.duplicateBlock(id: store.pattern.blocks[index].id)
                },
                onDelete: {
                    store.deleteBlock(id: store.pattern.blocks[index].id)
                }
            )
        }
    }
}
