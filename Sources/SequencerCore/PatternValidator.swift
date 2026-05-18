import Foundation

public struct PatternValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    public var message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public enum PatternValidator {
    public static func validate(_ pattern: Pattern) -> [PatternValidationError] {
        var errors: [PatternValidationError] = []
        let loopDuration = pattern.loopDuration

        if pattern.loopLengthBars <= 0 {
            errors.append(PatternValidationError("Loop length must be at least 1 bar."))
        }

        for block in pattern.blocks {
            if block.duration.ticks <= 0 {
                errors.append(PatternValidationError("Chord Block \(block.id) must have a positive duration."))
            }
            if block.kind == .chord, block.degree == nil {
                errors.append(PatternValidationError("Chord Block \(block.id) is missing a scale degree."))
            }
            if block.midiChannel < 1 || block.midiChannel > 16 {
                errors.append(PatternValidationError("Chord Block \(block.id) MIDI channel must be 1...16."))
            }
            if block.probability < 0 || block.probability > 1 {
                errors.append(PatternValidationError("Chord Block \(block.id) probability must be 0...1."))
            }
        }

        if pattern.totalBlockDuration.ticks > loopDuration.ticks {
            errors.append(PatternValidationError("Chord Blocks exceed the configured loop length."))
        }

        return errors
    }
}
