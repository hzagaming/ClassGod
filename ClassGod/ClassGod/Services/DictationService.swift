import AppKit
import AVFoundation
import Combine

nonisolated enum DictationSpeech: Equatable { case preferredVoice, fallbackVoice }

@MainActor
protocol DictationSpeaking: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ text: String, language: String, rate: Float, repeats: Int) -> DictationSpeech
    func stop()
}

@MainActor
final class SystemDictationSpeaker: DictationSpeaking {
    private let volume: Float
    private var synthesizer: AVSpeechSynthesizer?

    init(volume: Float = 1) {
        self.volume = volume
    }

    var isSpeaking: Bool { synthesizer?.isSpeaking ?? false }

    func speak(_ text: String, language: String, rate: Float, repeats: Int) -> DictationSpeech {
        stop()
        let synthesizer = AVSpeechSynthesizer()
        let voice = AVSpeechSynthesisVoice(language: language)
        for index in 0..<max(1, repeats) {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice
            utterance.rate = rate
            utterance.volume = volume
            utterance.preUtteranceDelay = index == 0 ? 0.1 : 0.8
            synthesizer.speak(utterance)
        }
        self.synthesizer = synthesizer
        return voice == nil ? .fallbackVoice : .preferredVoice
    }

    func stop() {
        synthesizer?.stopSpeaking(at: .immediate)
        synthesizer = nil
    }
}

@MainActor
final class DictationService: ObservableObject {
    static let shared = DictationService(speaker: SystemDictationSpeaker())
    @Published private(set) var source = ""
    @Published var voice = DictationVoice.automatic
    @Published var pace = DictationPace.steady
    @Published var repeatsTwice = false
    @Published var shuffles = true
    @Published private(set) var session = DictationSession()
    @Published private(set) var isSpeaking = false
    @Published private(set) var usedFallbackVoice = false
    private let speaker: DictationSpeaking
    private let notificationCenter: NotificationCenter
    private let workspaceCenter: NotificationCenter
    private let shuffle: ([String]) -> [String]
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var speechTask: Task<Void, Never>?

    init(
        speaker: DictationSpeaking,
        notificationCenter: NotificationCenter = .default,
        workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        shuffle: @escaping ([String]) -> [String] = { $0.shuffled() }
    ) {
        self.speaker = speaker
        self.notificationCenter = notificationCenter
        self.workspaceCenter = workspaceCenter
        self.shuffle = shuffle
    }

    deinit {
        speechTask?.cancel()
        for (center, token) in observers { center.removeObserver(token) }
    }

    var wordList: DictationWordList { DictationPolicy.words(from: source) }

    func updateSource(_ value: String) {
        let bounded = DictationPolicy.boundedSource(value)
        guard bounded != source else { return }
        source = bounded
        newRound()
    }

    @discardableResult func start() -> Bool { begin(wordList.words) }

    @discardableResult func retryReview() -> Bool {
        session.isComplete && begin(session.reviewWords)
    }

    func replay() { speakCurrentWord() }

    func submit(_ answer: String) -> DictationSubmission {
        let result = session.submit(answer)
        if result == .correct { stopSpeaking() }
        return result
    }

    func reveal() {
        if session.reveal() { stopSpeaking() }
    }

    func advance() {
        guard session.advance() else { return }
        if session.currentWord == nil { stopSpeaking() } else { speakCurrentWord() }
    }

    func newRound() {
        stopSpeaking()
        session = DictationSession()
    }

    func clear() {
        source = ""
        newRound()
    }

    func stopSpeaking() {
        speaker.stop()
        endSpeech()
    }

    func refreshSpeaking() {
        guard isSpeaking, !speaker.isSpeaking else { return }
        endSpeech()
    }

    private func begin(_ words: [String]) -> Bool {
        var next = DictationSession()
        guard next.start(words: shuffles ? shuffle(words) : words) else { return false }
        stopSpeaking()
        session = next
        speakCurrentWord()
        return true
    }

    private func speakCurrentWord() {
        guard let word = session.currentWord else { return }
        let speech = speaker.speak(
            word,
            language: DictationPolicy.language(for: word, voice: voice),
            rate: pace.rate,
            repeats: repeatsTwice ? 2 : 1
        )
        usedFallbackVoice = speech == .fallbackVoice
        isSpeaking = true
        observeInterruptions()
        speechTask?.cancel()
        speechTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, let self, self.isSpeaking else { return }
                self.refreshSpeaking()
            }
        }
    }

    private func observeInterruptions() {
        guard observers.isEmpty else { return }
        let events: [(NotificationCenter, Notification.Name)] = [
            (notificationCenter, NSApplication.didResignActiveNotification),
            (workspaceCenter, NSWorkspace.willSleepNotification),
            (workspaceCenter, NSWorkspace.sessionDidResignActiveNotification),
        ]
        for (center, name) in events {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.stopSpeaking() }
            }
            observers.append((center, token))
        }
    }

    private func endSpeech() {
        speechTask?.cancel()
        speechTask = nil
        isSpeaking = false
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
    }
}
