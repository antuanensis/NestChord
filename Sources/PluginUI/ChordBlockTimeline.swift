import SequencerCore
import SwiftUI

struct ChordBlockTimeline: View {
    @ObservedObject var store: PatternStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Chord Blocks",
                detail: "\(nestFormatted(store.pattern.totalBlockDuration.beats)) / \(nestFormatted(store.pattern.loopDuration.beats)) beats",
                tint: validationTint
            )

            LoopProgressBar(progress: store.loopProgress, isActive: store.isPlaying)

            HStack(alignment: .center, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(Array(store.pattern.positionedBlocks.enumerated()), id: \.element.id) { _, positioned in
                            ChordBlockCard(
                                positionedBlock: positioned,
                                pattern: store.pattern,
                                isSelected: store.selectedBlockID == positioned.id,
                                isActive: store.currentBlockID == positioned.id && store.isPlaying,
                                width: blockWidth(for: positioned.block)
                            )
                            .onTapGesture {
                                store.selectedBlockID = positioned.id
                            }
                            .onTapGesture(count: 2) {
                                store.selectedBlockID = positioned.id
                                store.auditionSelectedBlock()
                            }
                            .draggable(positioned.id.uuidString)
                            .dropDestination(for: String.self) { items, _ in
                                handleBlockDrop(items, before: positioned.id)
                            }
                            .contextMenu {
                                Button("Duplicate") {
                                    store.duplicateBlock(id: positioned.id)
                                }
                                Button("Delete", role: .destructive) {
                                    store.deleteBlock(id: positioned.id)
                                }
                            }
                            .overlay(alignment: .trailing) {
                                ResizeHandle()
                                    .gesture(
                                        DragGesture(minimumDistance: 2)
                                            .onEnded { value in
                                                store.resizeBlock(
                                                    id: positioned.id,
                                                    beatDelta: value.translation.width / NestChordTheme.beatWidth
                                                )
                                            }
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 2)
                }

                Button(action: store.addChordBlock) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .frame(width: 52, height: 104)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(NestChordTheme.accent, in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
                .shadow(color: NestChordTheme.accent.opacity(0.25), radius: 12)
            }

            validationFooter
        }
        .nestPanel()
    }

    @ViewBuilder
    private var validationFooter: some View {
        let errors = PatternValidator.validate(store.pattern)
        if errors.isEmpty {
            Text("Timeline valid")
                .font(.caption.weight(.medium))
                .foregroundStyle(NestChordTheme.textSecondary)
        } else {
            Text(errors.map(\.description).joined(separator: "\n"))
                .font(.caption.weight(.medium))
                .foregroundStyle(NestChordTheme.warning)
        }
    }

    private var validationTint: Color {
        PatternValidator.validate(store.pattern).isEmpty ? NestChordTheme.textSecondary : NestChordTheme.warning
    }

    private func blockWidth(for block: ChordBlock) -> CGFloat {
        max(104, min(292, CGFloat(block.duration.beats) * NestChordTheme.beatWidth))
    }

    private func handleBlockDrop(_ items: [String], before targetID: UUID) -> Bool {
        guard let rawID = items.first,
              let sourceID = UUID(uuidString: rawID) else {
            return false
        }
        store.moveBlock(id: sourceID, before: targetID)
        return true
    }
}
