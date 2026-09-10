import SwiftUI

struct NumberSprintView: View {
    @ObservedObject var service = NumberSprintService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var answer = ""
    @State private var submission: NumberSubmission?
    @State private var confirmsReset = false
    @FocusState private var answerFocused: Bool
    let onClose: () -> Void
    private let accent = Color(red: 0.35, green: 0.78, blue: 1)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        ScrollViewReader { scroll in
            TrainingPanel(title: "numbers.title", subtitle: "numbers.subtitle", icon: "number.square.fill", accent: accent, onClose: onClose) {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    if !service.session.isStarted { setup }
                    else if service.session.isComplete { summary }
                    else { exercise }
                    Text("numbers.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 12 * zoom)).id("numbersTop")
            }
            .onChange(of: service.session.position) { _, _ in
                answer = ""; submission = nil
                answerFocused = service.session.currentQuestion != nil
                scroll.scrollTo("numbersTop", anchor: .top)
            }
        }
        .alert("numbers.reset_title", isPresented: $confirmsReset) {
            Button("numbers.end", role: .destructive) { service.reset(); answer = ""; submission = nil }
            Button("button.cancel", role: .cancel) {}
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 22 * zoom) {
            Text("numbers.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text("numbers.instructions").foregroundStyle(.white.opacity(0.65))
            Picker("numbers.difficulty", selection: $service.difficulty) {
                ForEach(NumberSprintDifficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.title).tag(difficulty)
                }
            }
            Text(service.difficulty.hint).foregroundStyle(accent)
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 70 * zoom, weight: .light)).foregroundStyle(accent)
                .frame(maxWidth: .infinity).padding(.vertical, 35 * zoom)
            Button("numbers.start") { start() }.buttonStyle(.borderedProminent)
        }
    }

    private var exercise: some View {
        VStack(alignment: .leading, spacing: 20 * zoom) {
            HStack {
                Text(String(format: String(localized: "numbers.question_format"), service.session.position + 1))
                    .foregroundStyle(accent).monospacedDigit()
                Spacer()
                Button("numbers.end") { confirmsReset = true }.buttonStyle(.bordered)
            }
            ProgressView(value: Double(service.session.results.count), total: 10)
                .accessibilityLabel("numbers.progress")
            if let question = service.session.currentQuestion {
                VStack(spacing: 24 * zoom) {
                    Text(verbatim: question.expression + " = ?")
                        .font(.system(size: 44 * zoom, weight: .semibold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .accessibilityLabel(Text(String(format: String(localized: "numbers.equation_format"), question.left, question.operation.spokenName, question.right)))
                    if let result = service.session.currentResult {
                        Label(LocalizedStringKey(result.wasRevealed ? "numbers.revealed" : "numbers.correct"), systemImage: result.wasRevealed ? "lightbulb" : "checkmark.circle.fill")
                            .foregroundStyle(result.wasRevealed ? .orange : accent)
                        Text(verbatim: "\(question.expression) = \(question.answer)")
                            .font(.system(size: 24 * zoom, weight: .medium, design: .monospaced))
                    } else {
                        TextField("numbers.answer", text: $answer)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 24 * zoom, design: .monospaced))
                            .frame(maxWidth: 260 * zoom)
                            .focused($answerFocused)
                            .onSubmit(submit)
                            .onChange(of: answer) { _, value in
                                answer = String(value.prefix(12)); submission = nil
                            }
                            .accessibilityLabel("numbers.answer")
                        if submission == .invalid { Text("numbers.invalid").foregroundStyle(.orange) }
                        if submission == .incorrect { Text("numbers.incorrect").foregroundStyle(.orange) }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 170 * min(zoom, 1))
                .padding(24 * zoom)
                .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3)))
            }
            if service.session.currentResult != nil {
                Button(LocalizedStringKey(service.session.position == 9 ? "numbers.finish" : "numbers.next")) {
                    service.advance(); feedback()
                }
                .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            } else {
                HStack(spacing: 12 * zoom) {
                    Button("numbers.submit", action: submit).buttonStyle(.borderedProminent)
                    Button("numbers.reveal") { service.reveal(); answerFocused = false; feedback() }.buttonStyle(.bordered)
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 18 * zoom) {
            Text("numbers.complete").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text(String(format: String(localized: "numbers.score_format"), service.session.solvedCount, service.session.firstTryCount))
                .foregroundStyle(accent)
            ForEach(Array(service.session.results.enumerated()), id: \.offset) { _, result in
                HStack {
                    Image(systemName: result.wasRevealed ? "lightbulb" : "checkmark.circle.fill")
                        .foregroundStyle(result.wasRevealed ? .orange : accent)
                    Text(verbatim: "\(result.question.expression) = \(result.question.answer)").monospacedDigit()
                    Spacer()
                    Text(LocalizedStringKey(result.wasRevealed ? "numbers.revealed_short" : result.attempts == 1 ? "numbers.first_try" : "numbers.corrected"))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(10 * zoom)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10 * zoom))
            }
            Button("numbers.new_round") { service.reset(); answer = ""; submission = nil; feedback() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func start() {
        answer = ""; submission = nil
        service.start(); answerFocused = true; feedback()
    }

    private func submit() {
        submission = service.submit(answer)
        if submission == .correct { answerFocused = false; HapticManager.shared.success() }
        else if submission == .incorrect { HapticManager.shared.warning() }
    }

    private func feedback() { SoundEffectManager.shared.playButtonClick(); HapticManager.shared.generic() }
}

private extension NumberSprintDifficulty {
    var title: LocalizedStringKey {
        switch self {
        case .warmUp: "numbers.level.warm_up"
        case .mixed: "numbers.level.mixed"
        case .challenge: "numbers.level.challenge"
        }
    }
    var hint: LocalizedStringKey {
        switch self {
        case .warmUp: "numbers.hint.warm_up"
        case .mixed: "numbers.hint.mixed"
        case .challenge: "numbers.hint.challenge"
        }
    }
}

private extension NumberOperation {
    var spokenName: String {
        switch self {
        case .add: String(localized: "numbers.plus")
        case .subtract: String(localized: "numbers.minus")
        case .multiply: String(localized: "numbers.times")
        }
    }
}
