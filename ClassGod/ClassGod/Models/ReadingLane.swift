import Foundation

nonisolated enum ReadingLanePolicy {
    static let maximumCharacters = 50_000
    static let passageLength = 800

    static func boundedSource(_ text: String) -> String {
        String(text.prefix(maximumCharacters))
    }

    static func passages(_ source: String) -> [String] {
        let text = boundedSource(source).replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var paragraphs: [String] = []
        var lines: [String] = []
        for line in text.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !lines.isEmpty { paragraphs.append(lines.joined(separator: "\n")); lines = [] }
            } else { lines.append(line) }
        }
        if !lines.isEmpty { paragraphs.append(lines.joined(separator: "\n")) }
        return paragraphs.flatMap { paragraph -> [String] in
            var remaining = Substring(paragraph.trimmingCharacters(in: .whitespacesAndNewlines))
            var pieces: [String] = []
            while let boundary = remaining.index(remaining.startIndex, offsetBy: passageLength, limitedBy: remaining.endIndex),
                  boundary != remaining.endIndex {
                let prefix = remaining[..<boundary]
                let whitespace = prefix.lastIndex(where: \.isWhitespace)
                let split = whitespace.flatMap { remaining.distance(from: remaining.startIndex, to: $0) >= passageLength / 2 ? $0 : nil } ?? boundary
                pieces.append(String(remaining[..<split]).trimmingCharacters(in: .whitespacesAndNewlines))
                remaining = remaining[split...]
                let start = remaining.unicodeScalars.firstIndex { !CharacterSet.whitespacesAndNewlines.contains($0) } ?? remaining.endIndex
                remaining = remaining[start...]
            }
            if !remaining.isEmpty { pieces.append(String(remaining)) }
            return pieces
        }
    }
}

nonisolated struct ReadingLaneSession: Equatable {
    private(set) var passages: [String] = []
    private(set) var position = 0
    var isStarted: Bool { !passages.isEmpty }
    var isComplete: Bool { isStarted && position == passages.count }
    var readCount: Int { position }
    var currentPassage: String? { passages.indices.contains(position) ? passages[position] : nil }

    mutating func start(source: String) -> Bool {
        let passages = ReadingLanePolicy.passages(source)
        guard !passages.isEmpty else { return false }
        self.passages = passages
        position = 0
        return true
    }

    @discardableResult mutating func advance() -> Bool {
        guard currentPassage != nil else { return false }
        position += 1
        return true
    }

    @discardableResult mutating func previous() -> Bool {
        guard position > 0 else { return false }
        position -= 1
        return true
    }
}
