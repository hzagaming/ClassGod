import Foundation

nonisolated enum DictationVoice: String, CaseIterable, Hashable {
    case automatic
    case chineseSimplified = "zh-CN"
    case chineseTraditional = "zh-TW"
    case english = "en-US"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case french = "fr-FR"
    case german = "de-DE"
    case spanish = "es-ES"
    case portuguese = "pt-BR"
    case russian = "ru-RU"
}

nonisolated enum DictationPace: CaseIterable, Hashable {
    case slow, steady
    var rate: Float { self == .slow ? 0.36 : 0.46 }
}

nonisolated enum DictationSubmission { case invalid, incorrect, correct, ignored }

nonisolated struct DictationWordList: Equatable {
    let words: [String]
    let skipped: Int
}

nonisolated enum DictationPolicy {
    static let maximumSourceLength = 4_000
    static let maximumWords = 50
    static let maximumWordLength = 60
    static let maximumAnswerLength = 120
    private static let separators: Set<Character> = [",", "，", "、", ";", "；", "\t"]
    private static let trailingMarks: Set<Character> = [".", "。", "!", "！", "?", "？", ",", "，", ";", "；", ":", "：", "、", "…"]

    static func boundedSource(_ text: String) -> String {
        String(text.prefix(maximumSourceLength))
    }

    static func normalized(_ text: String) -> String {
        var value = Substring(text.split(whereSeparator: \.isWhitespace).joined(separator: " "))
        while let last = value.last, last.isWhitespace || trailingMarks.contains(last) { value.removeLast() }
        return String(value)
    }

    static func matches(_ answer: String, word: String) -> Bool {
        let answer = normalized(answer)
        return !answer.isEmpty
            && answer.compare(normalized(word), options: [.caseInsensitive, .widthInsensitive]) == .orderedSame
    }

    static func words(from source: String) -> DictationWordList {
        var seen = Set<String>()
        var words: [String] = []
        var skipped = 0
        for piece in boundedSource(source).split(whereSeparator: { $0.isNewline || separators.contains($0) }) {
            let word = piece.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            let key = normalized(word).folding(options: [.caseInsensitive, .widthInsensitive], locale: nil)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            guard word.count <= maximumWordLength, words.count < maximumWords else { skipped += 1; continue }
            words.append(word)
        }
        return .init(words: words, skipped: skipped)
    }

    static func language(for word: String, voice: DictationVoice) -> String {
        guard voice == .automatic else { return voice.rawValue }
        if contains(word, "[\\p{Hiragana}\\p{Katakana}]") { return DictationVoice.japanese.rawValue }
        if contains(word, "\\p{Hangul}") { return DictationVoice.korean.rawValue }
        if contains(word, "\\p{Han}") { return DictationVoice.chineseSimplified.rawValue }
        if contains(word, "\\p{Cyrillic}") { return DictationVoice.russian.rawValue }
        return DictationVoice.english.rawValue
    }

    private static func contains(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}

nonisolated struct DictationResult: Equatable {
    let word: String
    let attempts: Int
    let wasRevealed: Bool
    var isFirstTry: Bool { !wasRevealed && attempts == 1 }
    var needsReview: Bool { wasRevealed || attempts > 1 }
}

nonisolated struct DictationSession: Equatable {
    private(set) var words: [String] = []
    private(set) var position = 0
    private(set) var attempts = 0
    private(set) var results: [DictationResult] = []
    var isStarted: Bool { !words.isEmpty }
    var isComplete: Bool { isStarted && position == words.count }
    var currentWord: String? { words.indices.contains(position) ? words[position] : nil }
    var currentResult: DictationResult? { results.indices.contains(position) ? results[position] : nil }
    var solvedCount: Int { results.filter { !$0.wasRevealed }.count }
    var firstTryCount: Int { results.filter(\.isFirstTry).count }
    var reviewWords: [String] { results.filter(\.needsReview).map(\.word) }

    mutating func start(words: [String]) -> Bool {
        guard (1...DictationPolicy.maximumWords).contains(words.count),
              words.allSatisfy({ $0.count <= DictationPolicy.maximumWordLength && !DictationPolicy.normalized($0).isEmpty })
        else { return false }
        self = DictationSession()
        self.words = words
        return true
    }

    mutating func submit(_ text: String) -> DictationSubmission {
        guard let word = currentWord, currentResult == nil else { return .ignored }
        let answer = String(text.prefix(DictationPolicy.maximumAnswerLength))
        guard !DictationPolicy.normalized(answer).isEmpty else { return .invalid }
        attempts += 1
        guard DictationPolicy.matches(answer, word: word) else { return .incorrect }
        results.append(.init(word: word, attempts: attempts, wasRevealed: false))
        return .correct
    }

    @discardableResult mutating func reveal() -> Bool {
        guard let word = currentWord, currentResult == nil else { return false }
        results.append(.init(word: word, attempts: attempts, wasRevealed: true))
        return true
    }

    @discardableResult mutating func advance() -> Bool {
        guard currentWord != nil, currentResult != nil else { return false }
        position += 1
        attempts = 0
        return true
    }
}
