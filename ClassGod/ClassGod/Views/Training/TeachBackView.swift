import SwiftUI

struct TeachBackView: View {
    @ObservedObject var service = TeachBackService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var confirmsClear = false
    @State private var copied: Bool?
    let onClose: () -> Void
    private let accent = Color(red: 0.35, green: 0.78, blue: 1)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        ScrollViewReader { scroll in
            TrainingPanel(title: "teach.title", subtitle: "teach.subtitle", icon: "text.bubble.fill", accent: accent, onClose: onClose) {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    if service.session.isReviewing { review } else { editor }
                    Text("teach.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 12 * zoom)).id("teachTop")
            }
            .onChange(of: service.session.step) { _, _ in scroll.scrollTo("teachTop", anchor: .top) }
            .onChange(of: service.session.isReviewing) { _, _ in scroll.scrollTo("teachTop", anchor: .top) }
            .onChange(of: service.session) { _, _ in copied = nil }
        }
        .alert("teach.clear_title", isPresented: $confirmsClear) {
            Button("teach.clear", role: .destructive) { service.clear() }
            Button("button.cancel", role: .cancel) {}
        }
    }

    private var editor: some View {
        let step = service.session.step
        return VStack(alignment: .leading, spacing: 18 * zoom) {
            HStack {
                Text(String(format: String(localized: "teach.step_format"), step.rawValue + 1)).foregroundStyle(accent)
                Spacer()
                clearButton
            }
            ProgressView(value: Double(step.rawValue), total: 4).accessibilityLabel("teach.progress")
            Text(LocalizedStringKey(step.titleKey)).font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text(LocalizedStringKey(step.promptKey)).foregroundStyle(.white.opacity(0.65))
            TextEditor(text: Binding(get: { service.session.text(for: step) }, set: { service.update(step, text: $0) }))
                .font(.system(size: 16 * zoom))
                .scrollContentBackground(.hidden)
                .padding(14 * zoom)
                .frame(height: (step == .topic ? 115 : 210) * zoom)
                .background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 14 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 14 * zoom).stroke(accent.opacity(0.3)))
                .accessibilityLabel(Text(LocalizedStringKey(step.titleKey)))
            Text(verbatim: "\(service.session.text(for: step).count) / \(step.limit)")
                .font(.system(size: 10 * zoom, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
            HStack {
                Button("teach.previous") { service.previous() }.buttonStyle(.bordered).disabled(step == .topic)
                Spacer()
                Button(LocalizedStringKey(step == .gap ? "teach.review" : "teach.next")) {
                    service.next(); HapticManager.shared.generic()
                }
                .buttonStyle(.borderedProminent).disabled(!service.session.canAdvance)
            }
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 18 * zoom) {
            Text("teach.review_title").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
            Text("teach.review_hint").foregroundStyle(.white.opacity(0.65))
            ForEach(TeachBackStep.allCases, id: \.self) { step in
                VStack(alignment: .leading, spacing: 10 * zoom) {
                    Text(LocalizedStringKey(step.titleKey)).fontWeight(.semibold).foregroundStyle(accent)
                    if service.session.text(for: step).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("teach.no_gap").foregroundStyle(.white.opacity(0.5))
                    } else {
                        Text(verbatim: service.session.text(for: step))
                            .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(16 * zoom)
                .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12 * zoom))
            }
            ForEach(TeachBackCheck.allCases, id: \.self) { check in
                Toggle(LocalizedStringKey(check.titleKey), isOn: Binding(
                    get: { service.session.checked.contains(check) },
                    set: { value in if value != service.session.checked.contains(check) { service.toggle(check) } }
                ))
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12 * zoom) { reviewActions }
                VStack(alignment: .leading, spacing: 12 * zoom) { reviewActions }
            }
            if let copied {
                Text(LocalizedStringKey(copied ? "teach.copied" : "teach.copy_failed"))
                    .foregroundStyle(copied ? accent : .orange)
            }
        }
    }

    @ViewBuilder private var reviewActions: some View {
        Button("teach.copy") {
            guard let summary = service.session.summary(headings: TeachBackStep.allCases.map { $0.heading }) else { return }
            NSPasteboard.general.clearContents()
            copied = NSPasteboard.general.setString(summary, forType: .string)
        }
        .buttonStyle(.borderedProminent)
        Button("teach.edit") { service.previous() }.buttonStyle(.bordered)
        clearButton
    }

    private var clearButton: some View {
        Button("teach.clear", role: .destructive) { confirmsClear = true }
            .buttonStyle(.bordered).disabled(!service.session.hasContent)
    }
}

private extension TeachBackStep {
    var titleKey: String {
        switch self {
        case .topic: "teach.topic"
        case .explanation: "teach.explanation"
        case .example: "teach.example"
        case .gap: "teach.gap"
        }
    }
    var promptKey: String { titleKey + "_prompt" }
    var heading: String { NSLocalizedString(titleKey, comment: "") }
}

private extension TeachBackCheck {
    var titleKey: String {
        switch self {
        case .ownWords: "teach.check.words"
        case .exampleFits: "teach.check.example"
        case .gapReviewed: "teach.check.gap"
        }
    }
}
