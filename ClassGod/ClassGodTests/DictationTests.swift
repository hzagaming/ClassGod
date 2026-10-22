import AppKit
import Testing
@testable import ClassGod

@Suite("Dictation")
struct DictationTests {
    @Test("Word lists split on lines, commas, and enumeration marks while keeping phrases")
    func splitsWordLists() {
        let list = DictationPolicy.words(from: "apple\nbanana, cherry、ice  cream；melon\t\tkiwi\r\n\n  grape  ")
        #expect(list.words == ["apple", "banana", "cherry", "ice cream", "melon", "kiwi", "grape"])
        #expect(list.skipped == 0)
    }

    @Test("Duplicates merge across case, width, spacing, and trailing punctuation")
    func mergesDuplicates() {
        let list = DictationPolicy.words(from: "Apple\napple\nＡＰＰＬＥ\napple.\n  apple  \n学习\n学习。")
        #expect(list.words == ["Apple", "学习"])
        #expect(list.skipped == 0)
    }

    @Test("Overlong entries and entries past the round limit are counted once, never silently dropped")
    func countsSkippedWords() {
        let long = String(repeating: "长", count: DictationPolicy.maximumWordLength + 1)
        let fitting = String(repeating: "长", count: DictationPolicy.maximumWordLength)
        let words = (0..<52).map { "w\($0)" } + [long, long]
        let list = DictationPolicy.words(from: words.joined(separator: "\n"))
        #expect(list.words == (0..<50).map { "w\($0)" })
        #expect(list.skipped == 3)
        #expect(DictationPolicy.words(from: fitting).words == [fitting])
    }

    @Test("Punctuation-only entries are ignored and oversized sources are bounded before parsing")
    func boundsSources() {
        #expect(DictationPolicy.words(from: "?\n!!\n。\n…\nok").words == ["ok"])
        let source = String(repeating: "a,", count: 3_000)
        #expect(DictationPolicy.boundedSource(source).count == DictationPolicy.maximumSourceLength)
        #expect(DictationPolicy.words(from: source) == DictationWordList(words: ["a"], skipped: 0))
    }

    @Test("Answers ignore case, width, and spacing but keep accents and scripts exact")
    func matchesAnswers() {
        #expect(DictationPolicy.matches("  ice   CREAM. ", word: "Ice cream"))
        #expect(DictationPolicy.matches("ｃａｆé", word: "café"))
        #expect(DictationPolicy.matches("学习", word: "学习。"))
        #expect(!DictationPolicy.matches("cafe", word: "café"))
        #expect(!DictationPolicy.matches("學習", word: "学习"))
        #expect(!DictationPolicy.matches("カタカナ", word: "かたかな"))
        #expect(!DictationPolicy.matches("", word: "apple"))
        #expect(!DictationPolicy.matches(" 。", word: "apple"))
    }

    @Test("Automatic voices follow each word's script while explicit voices always win")
    func resolvesVoices() {
        #expect(DictationPolicy.language(for: "苹果", voice: .automatic) == "zh-CN")
        #expect(DictationPolicy.language(for: "学生です", voice: .automatic) == "ja-JP")
        #expect(DictationPolicy.language(for: "カメラ", voice: .automatic) == "ja-JP")
        #expect(DictationPolicy.language(for: "사과", voice: .automatic) == "ko-KR")
        #expect(DictationPolicy.language(for: "яблоко", voice: .automatic) == "ru-RU")
        #expect(DictationPolicy.language(for: "apple", voice: .automatic) == "en-US")
        #expect(DictationPolicy.language(for: "apple", voice: .french) == "fr-FR")
        #expect(DictationPolicy.language(for: "苹果", voice: .chineseTraditional) == "zh-TW")
        #expect(DictationVoice.allCases.filter { $0 != .automatic }.allSatisfy { Locale(identifier: $0.rawValue).language.languageCode != nil })
    }

    @Test("Invalid input does not count as an attempt and a solved word ignores repeats")
    func validatesAnswers() {
        var session = DictationSession()
        #expect(session.start(words: ["apple", "pear"]) == true)
        #expect(session.submit("   ") == .invalid)
        #expect(session.attempts == 0)
        #expect(session.submit("aple") == .incorrect)
        #expect(session.submit("Apple") == .correct)
        #expect(session.submit("apple") == .ignored)
        #expect(session.solvedCount == 1)
        #expect(session.firstTryCount == 0)
        #expect(session.reviewWords == ["apple"])
        #expect(session.advance() == true)
        #expect(session.attempts == 0)
        #expect(session.currentWord == "pear")
    }

    @Test("Revealed words never count as solved and are queued for review")
    func scoresRevealsHonestly() {
        var session = DictationSession()
        #expect(session.start(words: ["one", "two"]) == true)
        #expect(session.advance() == false)
        #expect(session.reveal() == true)
        #expect(session.reveal() == false)
        #expect(session.submit("one") == .ignored)
        #expect(session.advance() == true)
        #expect(session.submit("two") == .correct)
        #expect(session.advance() == true)
        #expect(session.isComplete)
        #expect(session.currentWord == nil)
        #expect(session.advance() == false)
        #expect(session.solvedCount == 1)
        #expect(session.firstTryCount == 1)
        #expect(session.reviewWords == ["one"])
    }

    @Test("Unsafe rounds are rejected before any word is spoken")
    func rejectsInvalidRounds() {
        var session = DictationSession()
        #expect(session.start(words: []) == false)
        #expect(session.start(words: (0...DictationPolicy.maximumWords).map { "w\($0)" }) == false)
        #expect(session.start(words: ["?"]) == false)
        #expect(session.start(words: [String(repeating: "a", count: DictationPolicy.maximumWordLength + 1)]) == false)
        #expect(!session.isStarted)
    }
}

@Suite("Dictation service")
@MainActor
struct DictationServiceTests {
    @Test("Starting speaks the first word with its resolved voice, pace, and repeat count")
    func speaksFirstWord() {
        let rig = DictationRig()
        rig.service.updateSource("苹果\napple")
        rig.service.shuffles = false
        rig.service.repeatsTwice = true
        rig.service.pace = .slow
        #expect(rig.service.start())
        #expect(rig.speaker.requests == [.init(text: "苹果", language: "zh-CN", rate: DictationPace.slow.rate, repeats: 2)])
        #expect(rig.service.isSpeaking)
    }

    @Test("Answering silences the word, advancing speaks the next one, and finishing stays quiet")
    func followsRound() {
        let rig = DictationRig()
        rig.service.updateSource("one\ntwo")
        rig.service.shuffles = false
        #expect(rig.service.start())
        #expect(rig.service.submit("one") == .correct)
        #expect(!rig.service.isSpeaking)
        #expect(rig.speaker.stops >= 1)
        rig.service.advance()
        #expect(rig.speaker.requests.map(\.text) == ["one", "two"])
        rig.service.reveal()
        rig.service.advance()
        #expect(rig.service.session.isComplete)
        #expect(rig.speaker.requests.count == 2)
        #expect(!rig.service.isSpeaking)
        rig.service.replay()
        #expect(rig.speaker.requests.count == 2)
    }

    @Test("Replay repeats the current word, including after its answer is shown")
    func replaysCurrentWord() {
        let rig = DictationRig()
        rig.service.updateSource("river")
        #expect(rig.service.start())
        rig.service.replay()
        rig.service.reveal()
        rig.service.replay()
        #expect(rig.speaker.requests.map(\.text) == ["river", "river", "river"])
    }

    @Test("Speech stops when the app resigns active or the Mac sleeps", arguments: [false, true])
    func stopsOnEnvironmentChanges(sleep: Bool) async throws {
        let rig = DictationRig()
        rig.service.updateSource("quiet")
        #expect(rig.service.start())
        let stops = rig.speaker.stops
        if sleep { rig.workspace.post(name: NSWorkspace.willSleepNotification, object: nil) }
        else { rig.center.post(name: NSApplication.didResignActiveNotification, object: nil) }
        for _ in 0..<100 where rig.service.isSpeaking {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!rig.service.isSpeaking)
        #expect(rig.speaker.stops == stops + 1)
    }

    @Test("Finished speech releases its observers so later notifications are ignored")
    func releasesObserversAfterSpeech() async throws {
        let rig = DictationRig()
        rig.service.updateSource("done")
        #expect(rig.service.start())
        rig.speaker.isSpeaking = false
        rig.service.refreshSpeaking()
        #expect(!rig.service.isSpeaking)
        let stops = rig.speaker.stops
        rig.center.post(name: NSApplication.didResignActiveNotification, object: nil)
        try await Task.sleep(for: .milliseconds(50))
        #expect(rig.speaker.stops == stops)
    }

    @Test("Missing voices are reported until a word with an installed voice plays")
    func reportsFallbackVoice() {
        let rig = DictationRig()
        rig.service.updateSource("one\ntwo")
        rig.service.shuffles = false
        rig.speaker.result = .fallbackVoice
        #expect(rig.service.start())
        #expect(rig.service.usedFallbackVoice)
        rig.speaker.result = .preferredVoice
        rig.service.reveal()
        rig.service.advance()
        #expect(!rig.service.usedFallbackVoice)
    }

    @Test("Editing the list ends the round and silences speech")
    func editingEndsRound() {
        let rig = DictationRig()
        rig.service.updateSource("first")
        #expect(rig.service.start())
        rig.service.updateSource("second")
        #expect(!rig.service.session.isStarted)
        #expect(!rig.service.isSpeaking)
        rig.service.updateSource(String(repeating: "x", count: DictationPolicy.maximumSourceLength + 10))
        #expect(rig.service.source.count == DictationPolicy.maximumSourceLength)
    }

    @Test("Retrying review words starts a round with only those words")
    func retriesReviewWords() {
        let rig = DictationRig()
        rig.service.updateSource("a\nb\nc")
        rig.service.shuffles = false
        #expect(rig.service.start())
        #expect(rig.service.submit("a") == .correct); rig.service.advance()
        #expect(rig.service.submit("x") == .incorrect)
        #expect(rig.service.submit("b") == .correct); rig.service.advance()
        rig.service.reveal(); rig.service.advance()
        #expect(rig.service.session.isComplete)
        #expect(rig.service.retryReview())
        #expect(rig.service.session.words == ["b", "c"])
        #expect(rig.speaker.requests.last?.text == "b")
        while rig.service.session.currentWord != nil {
            #expect(rig.service.submit(rig.service.session.currentWord ?? "") == .correct)
            rig.service.advance()
        }
        #expect(!rig.service.retryReview())
    }

    @Test("Shuffling applies only when enabled and keeps every word")
    func shufflesWhenEnabled() {
        let rig = DictationRig()
        rig.service.updateSource("a\nb\nc")
        #expect(rig.service.start())
        #expect(rig.service.session.words == ["c", "b", "a"])
        rig.service.newRound()
        rig.service.shuffles = false
        #expect(rig.service.start())
        #expect(rig.service.session.words == ["a", "b", "c"])
    }

    @Test("A new round or clearing returns to setup without speaking")
    func returnsToSetup() {
        let rig = DictationRig()
        rig.service.updateSource("word")
        #expect(rig.service.start())
        rig.service.newRound()
        #expect(!rig.service.session.isStarted)
        #expect(rig.service.source == "word")
        #expect(!rig.service.isSpeaking)
        rig.service.clear()
        #expect(rig.service.source.isEmpty)
        #expect(!rig.service.start())
        #expect(rig.speaker.requests.count == 1)
    }

    @Test("The system speaker queues and stops real utterances silently")
    func drivesSystemSpeaker() async throws {
        let speaker = SystemDictationSpeaker(volume: 0)
        _ = speaker.speak("ClassGod", language: "en-US", rate: DictationPace.steady.rate, repeats: 2)
        for _ in 0..<100 where !speaker.isSpeaking {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(speaker.isSpeaking)
        speaker.stop()
        for _ in 0..<100 where speaker.isSpeaking {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!speaker.isSpeaking)
    }
}

@MainActor
private final class DictationRig {
    let speaker = FakeDictationSpeaker()
    let center = NotificationCenter()
    let workspace = NotificationCenter()
    lazy var service = DictationService(
        speaker: speaker, notificationCenter: center, workspaceCenter: workspace, shuffle: { $0.reversed() }
    )
}

@MainActor
private final class FakeDictationSpeaker: DictationSpeaking {
    struct Request: Equatable {
        let text: String
        let language: String
        let rate: Float
        let repeats: Int
    }

    var requests: [Request] = []
    var stops = 0
    var isSpeaking = false
    var result = DictationSpeech.preferredVoice

    func speak(_ text: String, language: String, rate: Float, repeats: Int) -> DictationSpeech {
        requests.append(.init(text: text, language: language, rate: rate, repeats: repeats))
        isSpeaking = true
        return result
    }

    func stop() {
        stops += 1
        isSpeaking = false
    }
}
