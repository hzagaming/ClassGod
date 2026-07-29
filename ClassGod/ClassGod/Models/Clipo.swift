import Foundation

enum ClipoType: String, Codable, CaseIterable, Identifiable, Sendable {
    case text
    case url
    case code
    case image
    case file
    case richText
    case data

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .text: String(localized: "clipo.type.text")
        case .url: String(localized: "clipo.type.url")
        case .code: String(localized: "clipo.type.code")
        case .image: String(localized: "clipo.type.image")
        case .file: String(localized: "clipo.type.file")
        case .richText: String(localized: "clipo.type.richText")
        case .data: String(localized: "clipo.type.data")
        }
    }

    var iconName: String {
        switch self {
        case .text: "text.alignleft"
        case .url: "link"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .image: "photo"
        case .file: "doc"
        case .richText: "textformat"
        case .data: "shippingbox"
        }
    }
}

struct ClipoRepresentation: Codable, Equatable, Sendable {
    let type: String
    let data: Data

    var stringValue: String? {
        if type.lowercased().contains("utf16") {
            return String(data: data, encoding: .utf16)
        }
        return String(data: data, encoding: .utf8)
    }
}

struct ClipoPayloadItem: Codable, Equatable, Sendable {
    let representations: [ClipoRepresentation]
}

struct ClipoPayload: Codable, Equatable, Sendable {
    let items: [ClipoPayloadItem]

    var plainText: String? {
        let preferred = ["public.utf8-plain-text", "public.utf16-external-plain-text", "public.text"]
        for type in preferred {
            if let value = firstString(forType: type), !value.isEmpty { return value }
        }
        return items.lazy.flatMap(\.representations).first { $0.type.contains("text") }?.stringValue
    }

    var fileURLs: [URL] {
        items.flatMap(\.representations).compactMap { representation in
            guard representation.type == "public.file-url",
                  let value = representation.stringValue,
                  let url = URL(string: value), url.isFileURL else { return nil }
            return url
        }
    }

    var inferredType: ClipoType {
        if !fileURLs.isEmpty { return .file }
        if containsType(["public.png", "public.jpeg", "public.tiff", "public.heic", "public.image"]) { return .image }
        if containsType(["public.rtf", "public.html"]) { return .richText }
        if let plainText { return ClipoContentClassifier.type(for: plainText) }
        return .data
    }

    var preview: String {
        if let plainText { return ClipoPreview.make(from: plainText) }
        if let file = fileURLs.first {
            return fileURLs.count == 1 ? file.lastPathComponent : String(format: String(localized: "clipo.files_count"), fileURLs.count)
        }
        switch inferredType {
        case .image: return String(localized: "clipo.image")
        case .richText: return String(localized: "clipo.rich_text")
        default: return String(localized: "clipo.binary_data")
        }
    }

    var searchableText: String {
        plainText ?? fileURLs.map(\.lastPathComponent).joined(separator: " ")
    }

    var fingerprint: String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for representation in items.flatMap(\.representations) {
            for byte in representation.type.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
            for byte in representation.data {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }
        return String(hash, radix: 16)
    }

    private func firstString(forType type: String) -> String? {
        items.lazy.flatMap(\.representations).first { $0.type == type }?.stringValue
    }

    private func containsType(_ prefixes: [String]) -> Bool {
        items.lazy.flatMap(\.representations).contains { representation in
            prefixes.contains { representation.type.hasPrefix($0) }
        }
    }
}

struct ClipoItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var content: String
    var preview: String
    var type: ClipoType
    var payload: ClipoPayload?
    var fingerprint: String
    var sourceApp: String?
    var sourceBundleIdentifier: String?
    var createdAt: Date
    var lastUsedAt: Date
    var isPinned: Bool
    var slotNumber: Int?

    init(
        id: UUID = UUID(),
        content: String,
        preview: String? = nil,
        type: ClipoType? = nil,
        payload: ClipoPayload? = nil,
        fingerprint: String? = nil,
        sourceApp: String? = nil,
        sourceBundleIdentifier: String? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        isPinned: Bool = false,
        slotNumber: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.preview = preview ?? ClipoPreview.make(from: content)
        self.type = type ?? ClipoContentClassifier.type(for: content)
        self.payload = payload
        self.fingerprint = fingerprint ?? content
        self.sourceApp = sourceApp
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isPinned = isPinned
        self.slotNumber = slotNumber
    }

    init(payload: ClipoPayload, sourceApp: String?, sourceBundleIdentifier: String?) {
        let content = payload.searchableText
        self.init(
            content: content.isEmpty ? payload.preview : content,
            preview: payload.preview,
            type: payload.inferredType,
            payload: payload,
            fingerprint: payload.fingerprint,
            sourceApp: sourceApp,
            sourceBundleIdentifier: sourceBundleIdentifier
        )
    }

    var estimatedStorageBytes: Int {
        if let payload {
            return payload.items.flatMap(\.representations).reduce(0) { partial, representation in
                partial + representation.type.utf8.count + representation.data.count
            }
        }
        return content.utf8.count + preview.utf8.count
    }
}

enum ClipoImportError: LocalizedError {
    case fileTooLarge

    var errorDescription: String? {
        String(localized: "clipo.import_too_large")
    }
}

enum ClipoAutoDeletePolicy: Int, Codable, CaseIterable, Identifiable, Sendable {
    case never = 0
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30

    var id: Int { rawValue }
    var displayName: String {
        switch self {
        case .never: String(localized: "clipo.auto_delete.0")
        case .oneDay: String(localized: "clipo.auto_delete.1")
        case .sevenDays: String(localized: "clipo.auto_delete.7")
        case .thirtyDays: String(localized: "clipo.auto_delete.30")
        }
    }
}

struct ClipoSettings: Codable, Equatable, Sendable {
    var monitorClipboard = true
    var maxHistoryItems = 200
    var ignoreDuplicates = true
    var ignoreSensitiveApps = true
    var sensitiveBundleIdentifiers = [
        "com.1password.1password",
        "com.bitwarden.desktop",
        "com.apple.keychainaccess",
        "com.dashlane.dashlanemac",
        "org.keepassx.keepassxc",
    ]
    var autoDeletePolicy = ClipoAutoDeletePolicy.never
    var restoreClipboardAfterPaste = true
    var restoreClipboardAfterSave = true
    var pasteDelay = 0.05
    var searchCaseSensitive = false
    var fuzzySearch = false
    var showSourceApp = true
    var showTimestamp = true
    var compactRows = false

    var normalized: Self {
        var value = self
        value.maxHistoryItems = max(0, min(value.maxHistoryItems, 2_000))
        value.pasteDelay = max(0, min(value.pasteDelay, 1))
        var seenBundleIdentifiers = Set<String>()
        value.sensitiveBundleIdentifiers = value.sensitiveBundleIdentifiers.compactMap { identifier in
            let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 255 else { return nil }
            return seenBundleIdentifiers.insert(trimmed.lowercased()).inserted ? trimmed : nil
        }
        return value
    }
}

enum ClipoClipboardRestorePolicy {
    static func shouldRestore(expectedChangeCount: Int, currentChangeCount: Int) -> Bool {
        expectedChangeCount == currentChangeCount
    }
}

enum ClipoPreview {
    static func make(from content: String, limit: Int = 180) -> String {
        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard normalized.count > limit else { return normalized }
        return String(normalized.prefix(limit)) + "…"
    }
}

enum ClipoContentClassifier {
    static func type(for content: String) -> ClipoType {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil, !trimmed.contains(where: \.isWhitespace) {
            return .url
        }

        let markers = ["let ", "var ", "func ", "class ", "struct ", "import ", "=>", "</", "{", "};", "#!/"]
        let markerCount = markers.reduce(0) { $0 + (trimmed.contains($1) ? 1 : 0) }
        if markerCount >= 2 || (markerCount == 1 && trimmed.contains("\n")) {
            return .code
        }
        return .text
    }
}

enum ClipoSourcePolicy {
    static func shouldRememberTarget(
        candidateBundleIdentifier: String?,
        ownBundleIdentifier: String?
    ) -> Bool {
        candidateBundleIdentifier != ownBundleIdentifier
    }

    static func effectiveBundleIdentifier(
        frontmost: String?,
        pasteTarget: String?,
        ownBundleIdentifier: String?
    ) -> String? {
        frontmost == ownBundleIdentifier ? pasteTarget : frontmost
    }
}

enum ClipoHistoryPolicy {
    static func updatedHistory(
        inserting item: ClipoItem,
        into history: [ClipoItem],
        settings: ClipoSettings,
        now: Date
    ) -> [ClipoItem] {
        var items = pruned(history, settings: settings, now: now)
        var incoming = item
        incoming.lastUsedAt = now
        incoming.slotNumber = nil

        if settings.ignoreDuplicates,
           let index = items.firstIndex(where: { $0.fingerprint == incoming.fingerprint }) {
            var existing = items.remove(at: index)
            existing.lastUsedAt = now
            existing.sourceApp = incoming.sourceApp ?? existing.sourceApp
            existing.sourceBundleIdentifier = incoming.sourceBundleIdentifier ?? existing.sourceBundleIdentifier
            items.insert(existing, at: 0)
        } else {
            incoming = ClipoItem(
                content: incoming.content,
                preview: incoming.preview,
                type: incoming.type,
                payload: incoming.payload,
                fingerprint: incoming.fingerprint,
                sourceApp: incoming.sourceApp,
                sourceBundleIdentifier: incoming.sourceBundleIdentifier,
                createdAt: incoming.createdAt,
                lastUsedAt: now,
                isPinned: incoming.isPinned
            )
            items.insert(incoming, at: 0)
        }
        return trimmed(items, limit: settings.maxHistoryItems)
    }

    static func pruned(_ history: [ClipoItem], settings: ClipoSettings, now: Date) -> [ClipoItem] {
        guard settings.autoDeletePolicy != .never else { return trimmed(history, limit: settings.maxHistoryItems) }
        let cutoff = now.addingTimeInterval(-Double(settings.autoDeletePolicy.rawValue) * 86_400)
        return trimmed(history.filter { $0.isPinned || $0.lastUsedAt >= cutoff }, limit: settings.maxHistoryItems)
    }

    static func trimmed(
        _ history: [ClipoItem],
        limit: Int,
        byteLimit: Int = 256 * 1_024 * 1_024
    ) -> [ClipoItem] {
        let count = max(0, limit)
        let pinned = history.filter(\.isPinned).sorted { $0.lastUsedAt > $1.lastUsedAt }
        let unpinned = history.filter { !$0.isPinned }
        var usedBytes = 0
        var result: [ClipoItem] = []
        for item in pinned + unpinned where result.count < count {
            let itemBytes = item.estimatedStorageBytes
            guard itemBytes <= max(0, byteLimit - usedBytes) else { continue }
            result.append(item)
            usedBytes += itemBytes
        }
        return result
    }
}

enum ClipoSearch {
    static func filtered(
        _ items: [ClipoItem],
        query: String,
        type: ClipoType?,
        caseSensitive: Bool,
        fuzzy: Bool
    ) -> [ClipoItem] {
        items.filter { item in
            guard type == nil || item.type == type else { return false }
            guard !query.isEmpty else { return true }
            let searchable = item.content + " " + item.preview + " " + (item.sourceApp ?? "")
            if fuzzy { return fuzzyMatch(searchable, query: query, caseSensitive: caseSensitive) }
            if caseSensitive { return searchable.contains(query) }
            return searchable.localizedCaseInsensitiveContains(query)
        }
    }

    private static func fuzzyMatch(_ text: String, query: String, caseSensitive: Bool) -> Bool {
        let source = caseSensitive ? text : text.lowercased()
        let target = caseSensitive ? query : query.lowercased()
        guard !target.isEmpty else { return true }
        var index = target.startIndex
        for character in source where character == target[index] {
            index = target.index(after: index)
            if index == target.endIndex { return true }
        }
        return false
    }
}
