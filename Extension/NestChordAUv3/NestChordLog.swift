import OSLog

enum NestChordLog {
    static let subsystem = "com.nestchord.NestChord"

    static let auv3 = Logger(subsystem: subsystem, category: "AUv3")
    static let render = Logger(subsystem: subsystem, category: "Render")
    static let state = Logger(subsystem: subsystem, category: "State")
    static let midi = Logger(subsystem: subsystem, category: "MIDI")
}
