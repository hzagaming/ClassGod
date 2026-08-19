import SwiftUI

struct NotesView: View {
    @ObservedObject private var service = NotesService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var searchText = ""
    @State private var confirmDelete = false
    let onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var visibleNotes: [ClassGodNote] { service.filteredNotes(query: searchText) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 230 * zoomScale)
                Divider().background(Color.white.opacity(0.1))
                editor
            }
        }
        .background(Color.black)
        .tint(accent)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: zoomScale)
                .allowsHitTesting(false)
        )
        .confirmationDialog("notes.delete_title", isPresented: $confirmDelete) {
            Button("notes.delete", role: .destructive) {
                guard let id = service.selectedNoteID else { return }
                if service.delete(id, visibleNotes: visibleNotes) {
                    SoundEffectManager.shared.playTabDeleted()
                    HapticManager.shared.warning()
                }
            }
            Button("button.cancel", role: .cancel) {}
        } message: {
            Text("notes.delete_message")
        }
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: onClose) {
                Image(systemName: "minus")
                    .font(.system(size: 11 * zoomScale, weight: .bold))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.65))
            .accessibilityLabel(Text("button.close"))

            Image(systemName: "note.text")
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: zoomScale) {
                Text("notes.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                Text("notes.always_visible")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }
            Spacer()
            Text("notes.autosave")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.green.opacity(0.75))
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.025))
    }

    private var sidebar: some View {
        VStack(spacing: 8 * zoomScale) {
            HStack(spacing: 7 * zoomScale) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.35))
                TextField("notes.search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.3))
                    .accessibilityLabel(Text("button.clear"))
                }
                Button {
                    createNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
                .accessibilityLabel(Text("notes.new"))
            }
            .padding(8 * zoomScale)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))

            if visibleNotes.isEmpty {
                Spacer()
                VStack(spacing: 7 * zoomScale) {
                    Image(systemName: "note.text")
                        .font(.system(size: 24 * zoomScale))
                    Text(searchText.isEmpty ? "notes.empty" : "notes.no_results")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.35))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 5 * zoomScale) {
                        ForEach(visibleNotes) { note in
                            noteRow(note)
                        }
                    }
                }
            }
        }
        .padding(10 * zoomScale)
        .background(Color(white: 0.035))
    }

    private func noteRow(_ note: ClassGodNote) -> some View {
        let selected = service.selectedNoteID == note.id
        return Button {
            if service.select(note.id) {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
            }
        } label: {
            VStack(alignment: .leading, spacing: 4 * zoomScale) {
                HStack(spacing: 5 * zoomScale) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8 * zoomScale))
                            .foregroundStyle(accent)
                    }
                    Text(note.inferredTitle ?? String(localized: "notes.untitled"))
                        .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                Text(note.preview.isEmpty ? String(localized: "notes.empty_body") : note.preview)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
                Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 7 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9 * zoomScale)
            .background(selected ? accent.opacity(0.22) : Color.white.opacity(0.035))
            .overlay(
                RoundedRectangle(cornerRadius: 7 * zoomScale)
                    .stroke(selected ? accent.opacity(0.65) : Color.clear, lineWidth: zoomScale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var editor: some View {
        if let note = service.selectedNote {
            VStack(spacing: 0) {
                HStack(spacing: 8 * zoomScale) {
                    TextField("notes.title_placeholder", text: titleBinding)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18 * zoomScale, weight: .bold, design: .rounded))

                    Button {
                        if service.togglePin(note.id) {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                        }
                    } label: {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin")
                    }
                    .notesToolbarButton(accent: accent, zoomScale: zoomScale)
                    .accessibilityLabel(Text(note.isPinned ? "notes.unpin" : "notes.pin"))

                    Button {
                        confirmDelete = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .notesToolbarButton(accent: .red, zoomScale: zoomScale)
                    .accessibilityLabel(Text("notes.delete"))
                }
                .padding(14 * zoomScale)

                Divider().background(Color.white.opacity(0.08))

                TextEditor(text: bodyBinding)
                    .font(.system(size: 13 * zoomScale, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(10 * zoomScale)
                    .background(Color.black)
                    .id(note.id)
            }
        } else {
            VStack(spacing: 12 * zoomScale) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 38 * zoomScale))
                    .foregroundStyle(accent.opacity(0.7))
                Text("notes.select_or_create")
                    .font(.system(size: 12 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                Button("notes.new") { createNote() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { service.selectedNote?.title ?? "" },
            set: service.updateSelectedTitle
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { service.selectedNote?.body ?? "" },
            set: service.updateSelectedBody
        )
    }

    private func createNote() {
        guard service.addNote() != nil else {
            ErrorToastManager.shared.show(
                title: String(localized: "notes.title"),
                message: String(localized: "notes.limit_reached")
            )
            HapticManager.shared.warning()
            return
        }
        searchText = ""
        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
    }
}

private extension View {
    func notesToolbarButton(accent: Color, zoomScale: CGFloat) -> some View {
        buttonStyle(.plain)
            .foregroundStyle(accent)
            .frame(width: 28 * zoomScale, height: 28 * zoomScale)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }
}
