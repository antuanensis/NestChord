import Foundation

public struct PatternStateEnvelope: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var pattern: Pattern

    public init(
        schemaVersion: Int = PatternStateEnvelope.currentSchemaVersion,
        pattern: Pattern
    ) {
        self.schemaVersion = schemaVersion
        self.pattern = pattern
    }

    public func encodedJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decodeJSON(_ data: Data) throws -> PatternStateEnvelope {
        try JSONDecoder().decode(PatternStateEnvelope.self, from: data)
    }
}
