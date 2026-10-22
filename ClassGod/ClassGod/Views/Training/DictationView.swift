import SwiftUI

struct DictationView: View {
    @ObservedObject var service = DictationService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @ObservedObject private var wallpaper = WallpaperEngine.shared
    @State private var answer = ""
    @State private var submission: DictationSubmission?
    @State private var confirmsReset = false
    @State private var confirmsClear = false
    @FocusState private var answerFocused: Bool
    let onClose: () -> Void
    private let accent = Color(red: 0.35, green: 0.78, blue: 1)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        ScrollViewReader { scroll in
            TrainingPanel(title: "dictation.title", subtitle: "dictation.subtitle", icon: "ear.fill", accent: accent, onClose: onClose) {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    if !service.session.isStarted { setup }
                    else if service.session.isComplete { summary }
                    else { exercise }
                    Text("dictation.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 12 * zoom)).id("dictationTop")
            }
            .onChange(of: service.session.position) { _, _ in
                answer = ""; submission = nil
                answerFocused = service.session.currentWord != nil
                scroll.scrollTo("dictationTop", anchor: .top)
            }
            .onChange(of: service.session.isStarted) { _, _ in scroll.scrollTo("dictationTop", anchor: .top) }
        }
        .alert("dictation.reset_title", isPresented: $confirmsReset) {
            Button("dictation.end", role: .destructive) { service.newRound(); answer = ""; submission = nil; feedback() }
            Button("button.cancel", role: .cancel) {}
        }
        .alert("dictation.clear_title", isPresented: $confirmsClear) {
            Button("dictation.clear", role: .destructive) { service.clear(); feedback() }
            Button("button.cancel", role: .cancel) {}
        }
    }

    private var setup: some View {
        let list = service.wordList
        return VStack(alignment: .leading, spacing: 16 * zoom) {
            Text("dictation.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text("dictation.instructions").foregroundStyle(.white.opacity(0.65))
            HStack {
                Label("dictation.words", systemImage: "list.bullet")
                Spacer()
                Text(verbatim: "\(service.source.count) / \(DictationPolicy.maximumSourceLength)")
                    .foregroundStyle(.white.opacity(0.5)).monospacedDigit()
            }
            TextEditor(text: Binding(get: { service.source }, set: service.updateSource))
                .font(.system(size: 14 * zoom))
                .scrollContentBackground(.hidden)
                .padding(14 * zoom)
                .frame(height: 180 * zoom)
                .background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 14 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 14 * zoom).stroke(accent.opacity(0.25)))
                .accessibilityLabel("dictation.words")
            Text(String(format: String(localized: "dictation.ready_format"), list.words.count))
                .foregroundStyle(accent).monospacedDigit()
            if list.skipped > 0 {
                Text(String(format: String(localized: "dictation.skipped_format"), list.skipped)).foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 12 * zoom) {
                Picker("dictation.voice", selection: $service.voice) {
                    ForEach(DictationVoice.allCases, id: \.self) { voice in voice.label.tag(voice) }
                }
                Picker("dictation.pace", selection: $service.pace) {
                    Text("dictation.pace.slow").tag(DictationPace.slow)
                    Text("dictation.pace.steady").tag(DictationPace.steady)
                }
                .pickerStyle(.segmented)
                Toggle("dictation.repeat_twice", isOn: $service.repeatsTwice)
                Toggle("dictation.shuffle", isOn: $service.shuffles)
            }
            .padding(16 * zoom)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14 * zoom))
            Label("dictation.headphones_hint", systemImage: "headphones").foregroundStyle(.white.opacity(0.65))
            wallpaperAudioHint
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { setupActions(canStart: !list.words.isEmpty) }
                VStack(alignment: .leading, spacing: 12 * zoom) { setupActions(canStart: !list.words.isEmpty) }
            }
        }
    }

    @ViewBuilder private func setupActions(canStart: Bool) -> some View {
        Button { start() } label: { Label("dictation.start", systemImage: "play.fill") }
            .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
            .disabled(!canStart)
        Button("dictation.clear", role: .destructive) { confirmsClear = true }
            .disabled(service.source.isEmpty)
    }

    private var exercise: some View {
        VStack(alignment: .leading, spacing: 20 * zoom) {
            HStack {
                Text(String(format: String(localized: "dictation.word_format"), service.session.position + 1, service.session.words.count))
                    .foregroundStyle(accent).monospacedDigit()
                Spacer()
                Button("dictation.end") { confirmsReset = true }
            }
            ProgressView(value: Double(service.session.results.count), total: Double(service.session.words.count))
                .accessibilityLabel("dictation.progress")
            if let word = service.session.currentWord {
                VStack(spacing: 18 * zoom) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 50 * zoom, weight: .light)).foregroundStyle(accent)
                        .symbolEffect(.variableColor.iterative, isActive: service.isSpeaking && Anim.enabled)
                        .accessibilityHidden(true)
                    Text(LocalizedStringKey(service.isSpeaking ? "dictation.speaking" : "dictation.listen_prompt"))
                        .foregroundStyle(.white.opacity(0.65))
                    Button { replay() } label: { Label("dictation.replay", systemImage: "arrow.counterclockwise") }
                        .keyboardShortcut("r", modifiers: .command)
                    if let result = service.session.currentResult {
                        Label(LocalizedStringKey(result.wasRevealed ? "dictation.revealed" : "dictation.correct"),
                              systemImage: result.wasRevealed ? "lightbulb" : "checkmark.circle.fill")
                            .foregroundStyle(result.wasRevealed ? .orange : accent)
                        Text(verbatim: word)
                            .font(.system(size: 30 * zoom, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                    } else {
                        TextField("dictation.answer", text: $answer)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 22 * zoom))
                            .frame(maxWidth: 380 * zoom)
                            .focused($answerFocused)
                            .onSubmit(submit)
                            .onChange(of: answer) { _, value in
                                let bounded = String(value.prefix(DictationPolicy.maximumAnswerLength))
                                if bounded != value { answer = bounded }
                                submission = nil
                            }
                            .accessibilityLabel("dictation.answer")
                        if submission == .invalid { Text("dictation.invalid").foregroundStyle(.orange) }
                        if submission == .incorrect { Text("dictation.incorrect").foregroundStyle(.orange) }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 220 * min(zoom, 1))
                .padding(24 * zoom)
                .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3)))
            }
            wallpaperAudioHint
            if service.usedFallbackVoice {
                Label("dictation.voice_fallback", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            }
            if service.session.currentResult != nil {
                Button(LocalizedStringKey(service.session.position + 1 == service.session.words.count ? "dictation.finish" : "dictation.next")) {
                    service.advance(); HapticManager.shared.generic()
                }
                .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true)).keyboardShortcut(.defaultAction)
            } else {
                HStack(spacing: 12 * zoom) {
                    Button("dictation.submit", action: submit).buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
                    Button("dictation.reveal") { service.reveal(); answerFocused = false; feedback() }
                }
            }
        }
    }

    private var summary: some View {
        let review = service.session.reviewWords
        return VStack(alignment: .leading, spacing: 18 * zoom) {
            Text("dictation.complete").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text(String(format: String(localized: "dictation.score_format"),
                        service.session.solvedCount, service.session.words.count, service.session.firstTryCount))
                .foregroundStyle(accent)
            if review.isEmpty {
                Label("dictation.perfect", systemImage: "star.fill").foregroundStyle(accent)
            }
            ForEach(Array(service.session.results.enumerated()), id: \.offset) { _, result in
                HStack {
                    Image(systemName: result.wasRevealed ? "lightbulb" : result.isFirstTry ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        .foregroundStyle(result.wasRevealed ? .orange : accent)
                    Text(verbatim: result.word).lineLimit(2)
                    Spacer()
                    Text(LocalizedStringKey(result.wasRevealed ? "dictation.revealed_short" : result.isFirstTry ? "dictation.first_try" : "dictation.corrected"))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(10 * zoom)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10 * zoom))
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { summaryActions(reviewCount: review.count) }
                VStack(alignment: .leading, spacing: 12 * zoom) { summaryActions(reviewCount: review.count) }
            }
        }
    }

    @ViewBuilder private func summaryActions(reviewCount: Int) -> some View {
        if reviewCount > 0 {
            Button(String(format: String(localized: "dictation.retry_format"), reviewCount)) { retry() }
                .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
        }
        Button("dictation.new_round") { service.newRound(); answer = ""; submission = nil; feedback() }
            .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: reviewCount == 0))
    }

    @ViewBuilder private var wallpaperAudioHint: some View {
        if wallpaper.isEnabled, wallpaper.isPlaying, !wallpaper.isMuted, wallpaper.volume > 0,
           wallpaper.currentWallpaper?.type == .video {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { wallpaperAudioContent }
                VStack(alignment: .leading, spacing: 10 * zoom) { wallpaperAudioContent }
            }
        }
    }

    @ViewBuilder private var wallpaperAudioContent: some View {
        Label("dictation.wallpaper_audio", systemImage: "music.note").foregroundStyle(.orange)
        Button("wallpaper.mute") { wallpaper.toggleMute(); feedback() }
    }

    private func start() {
        answer = ""; submission = nil
        if service.start() { answerFocused = true; HapticManager.shared.generic() }
    }

    private func retry() {
        answer = ""; submission = nil
        if service.retryReview() { answerFocused = true; HapticManager.shared.generic() }
    }

    private func replay() {
        service.replay()
        HapticManager.shared.generic()
    }

    private func submit() {
        submission = service.submit(answer)
        if submission == .correct { answerFocused = false; HapticManager.shared.success() }
        else if submission == .incorrect { HapticManager.shared.warning() }
    }

    private func feedback() { SoundEffectManager.shared.playButtonClick(); HapticManager.shared.generic() }
}

private extension DictationVoice {
    var label: Text {
        guard self != .automatic else { return Text("dictation.voice.automatic") }
        return Text(verbatim: Locale(identifier: rawValue).localizedString(forIdentifier: rawValue) ?? rawValue)
    }
}
