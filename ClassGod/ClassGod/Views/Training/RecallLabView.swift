import AppKit
import SwiftUI

private struct RecallEditorDraft: Identifiable {
    let id = UUID()
    let card: RecallCard?
}

struct RecallLabView: View {
    @ObservedObject var service = RecallLabService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""
    @State private var draft: RecallEditorDraft?
    @State private var pendingDeletion: RecallCard?
    @State private var showsDeleteConfirmation = false
    let onClose: () -> Void

    private let accent = Color(red: 0.35, green: 0.78, blue: 1)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var motion: Animation? { !reduceMotion && Anim.enabled ? .easeOut(duration: Anim.duration) : nil }
    private var filteredCards: [RecallCard] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return service.cards.filter {
            term.isEmpty || $0.question.localizedCaseInsensitiveContains(term)
                || $0.answer.localizedCaseInsensitiveContains(term) || $0.topic.localizedCaseInsensitiveContains(term)
        }.sorted {
            if $0.dueAt != $1.dueAt { return $0.dueAt < $1.dueAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    var body: some View {
        TrainingPanel(title: "recall.title", subtitle: "recall.subtitle", icon: MainPanelFeature.recallLab.icon, accent: accent, onClose: onClose) {
            VStack(alignment: .leading, spacing: 20 * zoom) {
                if let issue = service.storageIssue { storageNotice(issue) }
                if service.isReviewing {
                    reviewWorkspace
                } else {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        overview(now: context.date)
                    }
                    library
                }
            }
            .font(.system(size: 12 * zoom))
            .animation(motion, value: service.isRevealed)
        }
        .sheet(item: $draft) { draft in
            RecallCardEditor(card: draft.card, zoom: zoom, accent: accent) { question, answer, topic in
                guard service.saveCard(id: draft.card?.id, question: question, answer: answer, topic: topic) != nil else { return false }
                SoundEffectManager.shared.playTabSaved()
                HapticManager.shared.success()
                return true
            }
        }
        .alert("recall.delete_title", isPresented: $showsDeleteConfirmation, presenting: pendingDeletion) { card in
            Button("button.delete", role: .destructive) { delete(card) }
            Button("button.cancel", role: .cancel) {}
        } message: { card in
            Text(verbatim: card.question)
        }
        .onDisappear { service.flush() }
    }

    private func overview(now: Date) -> some View {
        let due = RecallPolicy.dueCards(service.cards, now: now).count
        return VStack(alignment: .leading, spacing: 16 * zoom) {
            Text("recall.intro")
                .font(.system(size: 23 * zoom, weight: .bold, design: .rounded))
            HStack(spacing: 12 * zoom) {
                metric("recall.due", value: due)
                metric("recall.total", value: service.cards.count)
                metric("recall.long_term", value: service.cards.filter { $0.level >= 3 }.count)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { overviewActions(due: due) }
                VStack(alignment: .leading, spacing: 12 * zoom) { overviewActions(due: due) }
            }
            if due == 0, let next = service.cards.map(\.dueAt).min() {
                HStack {
                    Text("recall.next_due")
                    Text(next, style: .relative)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    @ViewBuilder private func overviewActions(due: Int) -> some View {
        Button {
            if service.startReview() { feedback() }
        } label: {
            Label("recall.start", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(due == 0 || !service.canEdit)
        Button {
            draft = RecallEditorDraft(card: nil)
            feedback()
        } label: {
            Label("recall.add", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .disabled(!service.canEdit || service.cards.count >= RecallPolicy.maximumCards)
    }

    private func metric(_ label: LocalizedStringKey, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6 * zoom) {
            Text(verbatim: String(value))
                .font(.system(size: 27 * zoom, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
            Text(label).foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14 * zoom)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10 * zoom))
        .accessibilityElement(children: .combine)
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 12 * zoom) {
            HStack {
                Label("recall.library", systemImage: "rectangle.stack")
                    .fontWeight(.semibold)
                Spacer()
                Text(verbatim: "\(service.cards.count)/\(RecallPolicy.maximumCards)")
                    .foregroundStyle(.white.opacity(0.5))
            }
            TextField("recall.search", text: $query)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("recall.search")
            if filteredCards.isEmpty {
                VStack(spacing: 12 * zoom) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 36 * zoom)).foregroundStyle(accent)
                    Text(LocalizedStringKey(service.cards.isEmpty ? "recall.empty" : "recall.no_results"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30 * zoom)
            } else {
                LazyVStack(spacing: 8 * zoom) {
                    ForEach(filteredCards) { card in
                        HStack(spacing: 12 * zoom) {
                            VStack(alignment: .leading, spacing: 5 * zoom) {
                                if !card.topic.isEmpty {
                                    Text(verbatim: card.topic).font(.system(size: 9 * zoom, weight: .bold)).foregroundStyle(accent)
                                }
                                Text(verbatim: card.question).lineLimit(3)
                                HStack(spacing: 5 * zoom) {
                                    Text("recall.next_review")
                                    Text(card.dueAt, style: .date)
                                }
                                .font(.system(size: 9 * zoom)).foregroundStyle(.white.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                draft = RecallEditorDraft(card: card)
                                feedback()
                            } label: { Image(systemName: "pencil") }
                            .accessibilityLabel("button.edit")
                            Button(role: .destructive) {
                                if prefs.preferences.confirmBeforeDelete {
                                    pendingDeletion = card
                                    showsDeleteConfirmation = true
                                } else { delete(card) }
                            } label: { Image(systemName: "trash") }
                            .accessibilityLabel("button.delete")
                        }
                        .buttonStyle(.bordered)
                        .padding(14 * zoom)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10 * zoom))
                        .disabled(!service.canEdit)
                    }
                }
            }
            Text("recall.local_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
        }
    }

    private var reviewWorkspace: some View {
        VStack(alignment: .leading, spacing: 18 * zoom) {
            HStack {
                Text("recall.review")
                Spacer()
                Text(verbatim: "\(service.reviewedCount) / \(service.sessionTotal)").monospacedDigit()
                Button("recall.back_library") { service.endReview(); feedback() }.buttonStyle(.bordered)
            }
            ProgressView(value: Double(service.reviewedCount), total: Double(max(1, service.sessionTotal)))
                .accessibilityLabel("recall.progress")
            if let card = service.activeCard {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    Label("recall.question", systemImage: "brain.head.profile").foregroundStyle(accent)
                    if !card.topic.isEmpty { Text(verbatim: card.topic).foregroundStyle(.white.opacity(0.55)) }
                    Text(verbatim: card.question)
                        .font(.system(size: 24 * zoom, weight: .semibold, design: .rounded))
                        .textSelection(.enabled)
                    if service.isRevealed {
                        Divider()
                        Label("recall.answer", systemImage: "lightbulb.fill").foregroundStyle(accent)
                        Text(verbatim: card.answer).textSelection(.enabled)
                    } else {
                        Text("recall.think_first").foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200 * zoom, alignment: .topLeading)
                .padding(24 * zoom)
                .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3), lineWidth: zoom))
                if service.isRevealed {
                    Text("recall.grade_hint").foregroundStyle(.white.opacity(0.65))
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10 * zoom) { gradeButtons(card) }
                        VStack(alignment: .leading, spacing: 10 * zoom) { gradeButtons(card) }
                    }
                } else {
                    Button("recall.reveal") { if service.reveal() { feedback() } }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 16 * zoom) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 54 * zoom)).foregroundStyle(accent)
                    Text("recall.complete").font(.system(size: 24 * zoom, weight: .bold, design: .rounded))
                    Text("recall.complete_hint").foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 50 * zoom)
            }
        }
    }

    @ViewBuilder private func gradeButtons(_ card: RecallCard) -> some View {
        ForEach(RecallGrade.allCases, id: \.self) { grade in
            Button {
                if service.grade(grade) { feedback() }
            } label: {
                VStack(spacing: 4 * zoom) {
                    Text(grade.title).fontWeight(.semibold)
                    let next = RecallPolicy.reviewed(card, grade: grade, now: Date()).dueAt
                    Text(next, style: .relative).font(.system(size: 10 * zoom))
                }
                .padding(5 * zoom)
            }
            .buttonStyle(.bordered)
        }
    }

    private func storageNotice(_ issue: RecallLabService.StorageIssue) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(issue.message)
            if issue != .recovered { Button("recall.retry", action: service.retryStorage).buttonStyle(.bordered) }
        }
        .font(.system(size: 11 * zoom))
        .foregroundStyle(.orange)
        .padding(12 * zoom)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10 * zoom))
    }

    private func feedback() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func delete(_ card: RecallCard) {
        if service.delete(card.id) {
            SoundEffectManager.shared.playTabDeleted()
            HapticManager.shared.warning()
        }
    }
}

private extension RecallGrade {
    var title: LocalizedStringKey {
        switch self {
        case .again: "recall.grade.again"
        case .remembered: "recall.grade.remembered"
        case .easy: "recall.grade.easy"
        }
    }
}

private extension RecallLabService.StorageIssue {
    var message: LocalizedStringKey {
        switch self {
        case .recovered: "recall.storage.recovered"
        case .loadFailed: "recall.storage.load_failed"
        case .saveFailed: "recall.storage.save_failed"
        case .unsupportedVersion: "recall.storage.newer_version"
        }
    }
}

struct RecallCardEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question: String
    @State private var answer: String
    @State private var topic: String
    @State private var saveFailed = false
    let zoom: CGFloat
    let accent: Color
    let onSave: (String, String, String) -> Bool

    init(card: RecallCard?, zoom: CGFloat, accent: Color, onSave: @escaping (String, String, String) -> Bool) {
        _question = State(initialValue: card?.question ?? "")
        _answer = State(initialValue: card?.answer ?? "")
        _topic = State(initialValue: card?.topic ?? "")
        self.zoom = zoom
        self.accent = accent
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14 * zoom) {
                Text("recall.editor").font(.system(size: 20 * zoom, weight: .bold, design: .rounded))
                TextField("recall.topic", text: $topic).textFieldStyle(.roundedBorder)
                editor("recall.question", text: $question, limit: 500, height: 70)
                editor("recall.answer", text: $answer, limit: 5_000, height: 150)
                Text("recall.edit_hint").foregroundStyle(.secondary)
                if saveFailed { Text("recall.cannot_save").foregroundStyle(.orange) }
                HStack {
                    Button("button.cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("button.save") {
                        if onSave(question, answer, topic) { dismiss() } else { saveFailed = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(RecallPolicy.text(question, limit: 500).isEmpty || RecallPolicy.text(answer, limit: 5_000).isEmpty)
                }
            }
            .font(.system(size: 12 * zoom))
            .padding(24 * zoom)
        }
        .frame(
            width: min(480 * zoom, max(320, (NSScreen.main?.visibleFrame.width ?? 1_000) - 80)),
            height: min(510 * zoom, max(300, (NSScreen.main?.visibleFrame.height ?? 800) - 100))
        )
        .background(Color(red: 0.025, green: 0.075, blue: 0.12))
        .preferredColorScheme(.dark)
        .tint(accent)
        .onChange(of: topic) { _, value in topic = String(value.prefix(60)) }
    }

    private func editor(_ label: LocalizedStringKey, text: Binding<String>, limit: Int, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6 * zoom) {
            HStack {
                Text(label)
                Spacer()
                Text(verbatim: "\(text.wrappedValue.count)/\(limit)").foregroundStyle(.secondary)
            }
            TextEditor(text: text)
                .font(.system(size: 13 * zoom))
                .frame(height: height * zoom)
                .padding(6 * zoom)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8 * zoom))
                .accessibilityLabel(label)
                .onChange(of: text.wrappedValue) { _, value in text.wrappedValue = String(value.prefix(limit)) }
        }
    }
}
