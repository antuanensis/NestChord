import Foundation

public struct Timeline: Sendable {
    public var pattern: Pattern

    public init(pattern: Pattern) {
        self.pattern = pattern
    }

    public var positionedBlocks: [PositionedChordBlock] {
        pattern.positionedBlocks
    }

    public func loopPosition(for absoluteTime: MusicalTime) -> MusicalTime {
        let loopTicks = pattern.loopDuration.ticks
        guard loopTicks > 0 else { return .zero }

        let raw = absoluteTime.ticks % loopTicks
        return MusicalTime(ticks: raw >= 0 ? raw : raw + loopTicks)
    }

    public func blockCovering(loopPosition: MusicalTime) -> PositionedChordBlock? {
        positionedBlocks.first { positioned in
            positioned.block.kind != .hold &&
                positioned.start.ticks < loopPosition.ticks &&
                loopPosition.ticks < positioned.end.ticks
        }
    }
}
