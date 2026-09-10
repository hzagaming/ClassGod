import SwiftUI

struct ReadingLaneView: View {
    @ObservedObject var service = ReadingLaneService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var confirmsClear = false
    let onClose: () -> Void
    private let accent = Color(red: 0.35, green: 0.78, blue: 1)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        ScrollViewReader { scroll in
            TrainingPanel(title: "reading.title", subtitle: "reading.subtitle", icon: "text.alignleft", accent: accent, onClose: onClose) {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    if service.session.isStarted { reader } else { editor }
                    Text("reading.session_hint")
                        .font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 12 * zoom))
                .id("reading.top")
            }
            .onChange(of: service.session.position) { _, _ in scroll.scrollTo("reading.top", anchor: .top) }
            .onChange(of: service.session.isStarted) { _, _ in scroll.scrollTo("reading.top", anchor: .top) }
        }
        .alert("reading.clear_title", isPresented: $confirmsClear) {
            Button("reading.clear", role: .destructive) { service.clear() }
            Button("button.cancel", role: .cancel) {}
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 16 * zoom) {
            Text("reading.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text("reading.instructions").foregroundStyle(.white.opacity(0.65))
            HStack {
                Label("reading.source", systemImage: "doc.text")
                Spacer()
                Text(verbatim: "\(service.source.count) / \(ReadingLanePolicy.maximumCharacters)")
                    .foregroundStyle(.white.opacity(0.5)).monospacedDigit()
            }
            TextEditor(text: Binding(get: { service.source }, set: service.updateSource))
                .font(.system(size: 14 * zoom))
                .scrollContentBackground(.hidden)
                .padding(14 * zoom)
                .frame(height: 270 * zoom)
                .background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 14 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 14 * zoom).stroke(accent.opacity(0.25)))
                .accessibilityLabel("reading.source")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { editorActions }
                VStack(alignment: .leading, spacing: 12 * zoom) { editorActions }
            }
        }
    }

    @ViewBuilder private var editorActions: some View {
        Button {
            if service.start() { feedback() }
        } label: { Label("reading.start", systemImage: "play.fill") }
        .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
        .disabled(service.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        Button("reading.clear", role: .destructive) { confirmsClear = true }
            .disabled(service.source.isEmpty)
    }

    private var reader: some View {
        VStack(alignment: .leading, spacing: 20 * zoom) {
            ViewThatFits(in: .horizontal) {
                HStack { progressLabel; Spacer(); sourceButton }
                VStack(alignment: .leading, spacing: 10 * zoom) { progressLabel; sourceButton }
            }
            ProgressView(value: Double(service.session.readCount), total: Double(service.session.passages.count))
                .accessibilityLabel("reading.progress")
            if let passage = service.session.currentPassage {
                VStack(alignment: .leading, spacing: 18 * zoom) {
                    Text(String(format: String(localized: "reading.passage_format"), service.session.position + 1, service.session.passages.count))
                        .font(.system(size: 10 * zoom, weight: .bold, design: .monospaced)).foregroundStyle(accent)
                    Text(verbatim: passage)
                        .font(.system(size: 21 * zoom, design: .serif))
                        .lineSpacing(10 * zoom)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 160 * min(zoom, 1), alignment: .topLeading)
                .padding(26 * zoom)
                .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.25)))
                HStack {
                    previousButton
                    Spacer()
                    Button(LocalizedStringKey(service.session.position + 1 == service.session.passages.count ? "reading.finish" : "reading.next")) {
                        service.advance(); feedback()
                    }
                    .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
                }
            } else {
                VStack(spacing: 18 * zoom) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 50 * zoom)).foregroundStyle(accent)
                    Text("reading.complete").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
                    Text("reading.complete_hint").foregroundStyle(.white.opacity(0.65))
                    HStack(spacing: 12 * zoom) {
                        previousButton
                        Button("reading.restart") { _ = service.start(); feedback() }.buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity).padding(.vertical, 35 * zoom)
            }
        }
    }

    private var progressLabel: some View {
        Text(String(format: String(localized: "reading.progress_format"), service.session.readCount, service.session.passages.count))
            .monospacedDigit().foregroundStyle(accent)
    }

    private var sourceButton: some View {
        Button("reading.edit_source") { service.editSource(); feedback() }
    }

    private var previousButton: some View {
        Button("reading.previous") { service.previous(); feedback() }
            .disabled(service.session.position == 0)
    }

    private func feedback() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }
}
