import CoreMusicTheory
import Foundation

public enum ChordVoicer {
    public static func midiNotes(
        for chord: Chord,
        settings: VoicingSettings,
        previousNotes: [Int]? = nil
    ) -> [Int] {
        var notes = closeRootPositionNotes(for: chord, register: settings.register)
        notes = applyInversion(settings.inversion, to: notes)

        switch settings.preset {
        case .close:
            return notes
        case .open:
            return applyOpenVoicing(to: notes)
        case .drop2Stub:
            return notes
        }
    }

    private static func closeRootPositionNotes(for chord: Chord, register: Register) -> [Int] {
        var notes: [Int] = []
        var lastNote = Int.min

        for pitchClass in chord.pitchClasses {
            var midiNote = pitchClass.midiNoteNumber(octave: register.rootOctave)
            while midiNote <= lastNote {
                midiNote += 12
            }
            notes.append(midiNote)
            lastNote = midiNote
        }

        return notes
    }

    private static func applyInversion(_ inversion: Inversion, to notes: [Int]) -> [Int] {
        guard notes.count > 1 else { return notes }

        let inversionCount = min(inversion.rawValue, notes.count - 1)
        guard inversionCount > 0 else { return notes }

        var result = notes
        for _ in 0..<inversionCount {
            let moved = result.removeFirst() + 12
            result.append(moved)
        }
        return result
    }

    private static func applyOpenVoicing(to notes: [Int]) -> [Int] {
        guard notes.count >= 3 else { return notes }

        var result = notes
        result[1] += 12
        result.sort()
        return result
    }
}
