import AppKit
import ApplicationServices
import Combine

extension Notification.Name {
    static let clipoWillPaste = Notification.Name("clipoWillPaste")
}

nonisolated private struct ClipoStorageContainer: Codable, Sendable {
    let history: [ClipoItem]
    let slots: [Int: ClipoItem]
    let settings: ClipoSettings
}

nonisolated enum ClipoShortcutAction: Hashable, Sendable {
    case openPanel
    case saveSlot(Int)
    case copySlot(Int)
}

nonisolated struct ClipoPasteSession: Sendable {
    private(set) var generation: UInt = 0
    private(set) var isActive = false

    mutating func begin() -> UInt {
        generation &+= 1
        isActive = true
        return generation
    }

    mutating func cancel() {
        generation &+= 1
        isActive = false
    }

    func isCurrent(_ request: UInt) -> Bool {
        request == generation
    }

    mutating func complete(_ request: UInt) -> Bool {
        guard isActive, isCurrent(request) else { return false }
        isActive = false
        return true
    }
}

nonisolated struct ClipoSelectionSession: Sendable {
    private(set) var generation: UInt = 0
    private(set) var isActive = false

    mutating func begin() -> UInt {
        generation &+= 1
        isActive = true
        return generation
    }

    mutating func cancel() {
        generation &+= 1
        isActive = false
    }

    func isCurrent(_ request: UInt) -> Bool {
        isActive && request == generation
    }

    mutating func complete(_ request: UInt) -> Bool {
        guard isCurrent(request) else { return false }
        isActive = false
        return true
    }
}

@MainActor
final class ClipoService: ObservableObject {
    static let shared = ClipoService()

    @Published private(set) var history: [ClipoItem] = []
    @Published private(set) var slots: [Int: ClipoItem] = [:]
    @Published private(set) var shortcutRegistrationFailures = Set<ClipoShortcutAction>()
    @Published var settings = ClipoSettings() {
        didSet {
            let normalized = settings.normalized
            guard normalized == settings else {
                settings = normalized
                return
            }
            guard !isLoading else { return }
            if oldValue.openShortcut != settings.openShortcut
                || oldValue.slotSaveShortcuts != settings.slotSaveShortcuts
                || oldValue.slotCopyShortcuts != settings.slotCopyShortcuts {
                refreshHotKeys()
            }
            history = ClipoHistoryPolicy.pruned(history, settings: settings, now: Date())
            save()
            settings.monitorClipboard ? startMonitoring() : stopMonitoring()
        }
    }

    private var monitorTimer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoredChangeCounts = Set<Int>()
    private var isLoading = false
    private var pasteTarget: NSRunningApplication?
    private var isTrackingApplications = false
    private var selectionTask: Task<Void, Never>?
    private var selectionSession = ClipoSelectionSession()
    private var pasteSession = ClipoPasteSession()
    private var pendingPasteSnapshot: ClipoPayload?
    private var saveTask: Task<Void, Never>?
    private var hotKeyIDs: [UInt32] = []
    private var openPanelHandler: (() -> Void)?
    private let persistenceQueue = DispatchQueue(label: "com.hanazar.classgod.clipo.persistence", qos: .utility)

    private var storageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("ClassGod/Clipo", isDirectory: true)
    }

    private var storageURL: URL {
        storageDirectory.appendingPathComponent("clips.json")
    }

    private init() {
        load()
    }

    func start() {
        startTrackingApplications()
        rememberPasteTarget()
        if settings.monitorClipboard { startMonitoring() }
    }

    func stop() {
        cancelPendingPaste()
        stopMonitoring()
        stopTrackingApplications()
        selectionSession.cancel()
        selectionTask?.cancel()
        selectionTask = nil
        saveTask?.cancel()
        saveTask = nil
        unregisterHotKeys()
        openPanelHandler = nil
        enqueueSave()
        persistenceQueue.sync {}
    }

    func filteredHistory(query: String, type: ClipoType?) -> [ClipoItem] {
        ClipoSearch.filtered(
            history,
            query: query,
            type: type,
            caseSensitive: settings.searchCaseSensitive,
            fuzzy: settings.fuzzySearch
        )
    }

    func captureCurrentClipboard() {
        if recordCurrentPasteboard(sourceApp: effectiveSourceApplication()) {
            SoundEffectManager.shared.playTabSaved()
        }
    }

    func saveCurrentClipboard(to slotNumber: Int) {
        guard let item = makeItem(sourceApp: effectiveSourceApplication()) else { return }
        save(item, to: slotNumber)
    }

    func rememberPasteTarget() {
        rememberPasteTarget(NSWorkspace.shared.frontmostApplication)
    }

    private func rememberPasteTarget(_ app: NSRunningApplication?) {
        guard let app else { return }
        if ClipoSourcePolicy.shouldRememberTarget(
            candidateBundleIdentifier: app.bundleIdentifier,
            ownBundleIdentifier: Bundle.main.bundleIdentifier
        ) {
            pasteTarget = app
        }
    }

    private func startTrackingApplications() {
        guard !isTrackingApplications else { return }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceApplicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        isTrackingApplications = true
    }

    private func stopTrackingApplications() {
        guard isTrackingApplications else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        isTrackingApplications = false
    }

    @objc private func workspaceApplicationDidActivate(_ notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        rememberPasteTarget(app)
    }

    func copy(_ item: ClipoItem) {
        guard write(item) else { return }
        cancelPendingPaste()
        record(item)
        SoundEffectManager.shared.playButtonClick()
    }

    func paste(_ item: ClipoItem) {
        guard AXIsProcessTrusted() else {
            PermissionCenterService.shared.requestPermission(.accessibility)
            return
        }

        let candidateSnapshot = settings.restoreClipboardAfterPaste ? capturePayload() : nil
        let snapshot = ClipoPasteSnapshotPolicy.snapshot(
            existing: pendingPasteSnapshot,
            candidate: candidateSnapshot,
            hasPendingPaste: pasteSession.isActive
        )
        guard write(item) else { return }
        let request = pasteSession.begin()
        pendingPasteSnapshot = snapshot
        let writtenChangeCount = NSPasteboard.general.changeCount
        record(item)
        NotificationCenter.default.post(name: .clipoWillPaste, object: nil)
        if let target = pasteTarget, !target.isTerminated {
            target.activate(options: [.activateAllWindows])
        }
        let delay = max(0.05, settings.pasteDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            guard ClipoDeferredPastePolicy.shouldExecute(
                requestIsCurrent: self.pasteSession.isCurrent(request),
                expectedChangeCount: writtenChangeCount,
                currentChangeCount: NSPasteboard.general.changeCount
            ) else {
                if self.pasteSession.isCurrent(request) { self.cancelPendingPaste() }
                return
            }
            self.simulateKeyPress(keyCode: 9)
            guard let snapshot, self.settings.restoreClipboardAfterPaste else {
                self.finishPendingPaste(request)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.pasteSession.isCurrent(request) else { return }
                defer { self.finishPendingPaste(request) }
                guard ClipoClipboardRestorePolicy.shouldRestore(
                    expectedChangeCount: writtenChangeCount,
                    currentChangeCount: NSPasteboard.general.changeCount
                ) else { return }
                self.write(snapshot)
            }
        }
        SoundEffectManager.shared.playTabSaved()
    }

    func saveSelection(to slotNumber: Int) {
        guard (1...9).contains(slotNumber) else { return }
        guard AXIsProcessTrusted() else {
            PermissionCenterService.shared.requestPermission(.accessibility)
            return
        }

        let source = NSWorkspace.shared.frontmostApplication
        if settings.ignoreSensitiveApps,
           let bundleID = source?.bundleIdentifier,
           settings.sensitiveBundleIdentifiers.contains(where: { $0.caseInsensitiveCompare(bundleID) == .orderedSame }) {
            return
        }

        let previous = settings.restoreClipboardAfterSave
            ? ClipoPasteSnapshotPolicy.snapshot(
                existing: pendingPasteSnapshot,
                candidate: capturePayload(),
                hasPendingPaste: pasteSession.isActive
            )
            : nil
        let previousChangeCount = NSPasteboard.general.changeCount
        cancelPendingPaste()
        simulateKeyPress(keyCode: 8)

        selectionTask?.cancel()
        let request = selectionSession.begin()
        selectionTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if selectionSession.complete(request) {
                    selectionTask = nil
                }
            }
            for _ in 0..<16 {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, selectionSession.isCurrent(request) else { return }
                guard NSPasteboard.general.changeCount != previousChangeCount else { continue }
                guard let item = makeItem(sourceApp: source) else { return }
                let selectionChangeCount = NSPasteboard.general.changeCount
                markChangeIgnored(selectionChangeCount)
                save(item, to: slotNumber)
                if let previous {
                    try? await Task.sleep(for: .milliseconds(50))
                    guard !Task.isCancelled,
                          selectionSession.isCurrent(request),
                          ClipoClipboardRestorePolicy.shouldRestore(
                        expectedChangeCount: selectionChangeCount,
                        currentChangeCount: NSPasteboard.general.changeCount
                    ) else { return }
                    write(previous)
                }
                return
            }
        }
    }

    func save(_ item: ClipoItem, to slotNumber: Int) {
        guard (1...9).contains(slotNumber) else { return }
        var slotItem = item
        slotItem.slotNumber = slotNumber
        slotItem.lastUsedAt = Date()
        slots[slotNumber] = slotItem
        record(slotItem)
        save()
        SoundEffectManager.shared.playTabSaved()
    }

    func deleteSlot(_ number: Int) {
        guard slots.removeValue(forKey: number) != nil else { return }
        save()
        SoundEffectManager.shared.playTabDeleted()
    }

    func togglePin(_ id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        history[index].isPinned.toggle()
        history[index].lastUsedAt = Date()
        history = ClipoHistoryPolicy.trimmed(history, limit: settings.maxHistoryItems)
        save()
        SoundEffectManager.shared.playButtonClick()
    }

    func delete(_ id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        history.remove(at: index)
        save()
        SoundEffectManager.shared.playTabDeleted()
    }

    func clearHistory(keepingPinned: Bool = true) {
        let updated = keepingPinned ? history.filter(\.isPinned) : []
        guard updated != history else { return }
        history = updated
        save()
        SoundEffectManager.shared.playTabDeleted()
    }

    func resetAll() {
        guard !history.isEmpty || !slots.isEmpty || settings != ClipoSettings() else { return }
        history = []
        slots = [:]
        settings = ClipoSettings()
        save()
        SoundEffectManager.shared.playTabDeleted()
    }

    func export(to url: URL) throws {
        let data = try encodedStore()
        try data.write(to: url, options: .atomic)
    }

    func importStore(from url: URL) throws {
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard fileSize <= ClipoPayloadPolicy.maximumArchiveSize else { throw ClipoImportError.fileTooLarge }
        let data = try Data(contentsOf: url)
        guard data.count <= ClipoPayloadPolicy.maximumArchiveSize else { throw ClipoImportError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let container = try decoder.decode(ClipoStorageContainer.self, from: data)
        guard container.history.allSatisfy(ClipoPayloadPolicy.accepts),
              container.slots.values.allSatisfy(ClipoPayloadPolicy.accepts) else {
            throw ClipoImportError.invalidPayload
        }
        isLoading = true
        settings = container.settings
        history = ClipoHistoryPolicy.pruned(container.history, settings: settings, now: Date())
        slots = normalizedSlots(container.slots)
        isLoading = false
        refreshHotKeys()
        settings.monitorClipboard ? startMonitoring() : stopMonitoring()
        save()
    }

    func registerHotKeys(openPanel: @escaping () -> Void) {
        openPanelHandler = openPanel
        refreshHotKeys()
    }

    func resetShortcuts() {
        var updated = settings
        updated.resetShortcuts()
        settings = updated
    }

    private func refreshHotKeys() {
        unregisterHotKeys()
        guard let openPanelHandler else { return }
        shortcutRegistrationFailures.removeAll()

        registerHotKey(action: .openPanel, shortcut: settings.openShortcut, handler: openPanelHandler)
        for number in 1...9 {
            registerHotKey(
                action: .saveSlot(number),
                shortcut: settings.slotSaveShortcuts[number - 1],
                handler: { [weak self] in self?.saveSelection(to: number) }
            )
            registerHotKey(
                action: .copySlot(number),
                shortcut: settings.slotCopyShortcuts[number - 1],
                handler: { [weak self] in
                    guard let item = self?.slots[number] else { return }
                    self?.copy(item)
                }
            )
        }
    }

    private func registerHotKey(
        action: ClipoShortcutAction,
        shortcut: ClipoShortcut,
        handler: @escaping () -> Void
    ) {
        guard shortcut.isEnabled else { return }
        guard let keyCode = ShortcutManager.shared.keyCode(for: shortcut.key),
              let id = ShortcutManager.shared.registerCustomHotKey(
                keyCode: keyCode,
                cocoaModifiers: UInt32(shortcut.modifiers),
                handler: handler
              ) else {
            shortcutRegistrationFailures.insert(action)
            return
        }
        hotKeyIDs.append(id)
    }

    private func unregisterHotKeys() {
        hotKeyIDs.forEach(ShortcutManager.shared.unregisterCustomHotKey)
        hotKeyIDs.removeAll()
        shortcutRegistrationFailures.removeAll()
    }

    private func startMonitoring() {
        guard monitorTimer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        let timer = Timer(timeInterval: 0.8, target: self, selector: #selector(monitorTimerDidFire), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        monitorTimer = timer
    }

    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    @objc private func monitorTimerDidFire() {
        pollPasteboard()
    }

    private func pollPasteboard() {
        rememberPasteTarget()
        let changeCount = NSPasteboard.general.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        if ignoredChangeCounts.remove(changeCount) != nil { return }
        recordCurrentPasteboard(sourceApp: effectiveSourceApplication())
    }

    @discardableResult
    private func recordCurrentPasteboard(sourceApp: NSRunningApplication?) -> Bool {
        if settings.ignoreSensitiveApps,
           let bundleID = sourceApp?.bundleIdentifier,
           settings.sensitiveBundleIdentifiers.contains(where: { $0.caseInsensitiveCompare(bundleID) == .orderedSame }) {
            return false
        }
        guard let item = makeItem(sourceApp: sourceApp) else { return false }
        record(item)
        return true
    }

    private func effectiveSourceApplication() -> NSRunningApplication? {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let effectiveBundleID = ClipoSourcePolicy.effectiveBundleIdentifier(
            frontmost: frontmost?.bundleIdentifier,
            pasteTarget: pasteTarget?.bundleIdentifier,
            ownBundleIdentifier: Bundle.main.bundleIdentifier
        )
        if effectiveBundleID == frontmost?.bundleIdentifier { return frontmost }
        if effectiveBundleID == pasteTarget?.bundleIdentifier { return pasteTarget }
        return nil
    }

    private func makeItem(sourceApp: NSRunningApplication?) -> ClipoItem? {
        guard let payload = capturePayload() else { return nil }
        return ClipoItem(
            payload: payload,
            sourceApp: sourceApp?.localizedName,
            sourceBundleIdentifier: sourceApp?.bundleIdentifier
        )
    }

    private func record(_ item: ClipoItem) {
        history = ClipoHistoryPolicy.updatedHistory(
            inserting: item,
            into: history,
            settings: settings,
            now: Date()
        )
        save()
    }

    private func capturePayload(from pasteboard: NSPasteboard = .general) -> ClipoPayload? {
        guard let pasteboardItems = pasteboard.pasteboardItems else { return nil }
        var totalSize = 0
        var items: [ClipoPayloadItem] = []

        for pasteboardItem in pasteboardItems {
            var representations: [ClipoRepresentation] = []
            for type in pasteboardItem.types {
                guard let data = pasteboardItem.data(forType: type), !data.isEmpty,
                      data.count <= ClipoPayloadPolicy.maximumRepresentationSize,
                      data.count <= ClipoPayloadPolicy.maximumPayloadSize - totalSize else { continue }
                representations.append(ClipoRepresentation(type: type.rawValue, data: data))
                totalSize += data.count
            }
            if !representations.isEmpty {
                items.append(ClipoPayloadItem(representations: representations))
            }
        }
        return items.isEmpty ? nil : ClipoPayload(items: items)
    }

    @discardableResult
    private func write(_ item: ClipoItem) -> Bool {
        if let payload = item.payload { return write(payload) }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(item.content, forType: .string)
        if success { ignoreCurrentChange() }
        return success
    }

    @discardableResult
    private func write(_ payload: ClipoPayload) -> Bool {
        let pasteboardItems = payload.items.compactMap { item -> NSPasteboardItem? in
            let pasteboardItem = NSPasteboardItem()
            for representation in item.representations {
                pasteboardItem.setData(representation.data, forType: .init(representation.type))
            }
            return item.representations.isEmpty ? nil : pasteboardItem
        }
        guard !pasteboardItems.isEmpty else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.writeObjects(pasteboardItems)
        if success { ignoreCurrentChange() }
        return success
    }

    private func ignoreCurrentChange() {
        let count = NSPasteboard.general.changeCount
        ignoredChangeCounts.remove(count)
        lastChangeCount = count
    }

    private func markChangeIgnored(_ count: Int) {
        ignoredChangeCounts.insert(count)
        if ignoredChangeCounts.count > 32 {
            ignoredChangeCounts = Set(ignoredChangeCounts.sorted().suffix(32))
        }
    }

    private func simulateKeyPress(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func cancelPendingPaste() {
        pasteSession.cancel()
        pendingPasteSnapshot = nil
    }

    private func finishPendingPaste(_ request: UInt) {
        if pasteSession.complete(request) {
            pendingPasteSnapshot = nil
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let container = try decoder.decode(ClipoStorageContainer.self, from: data)
            guard container.history.allSatisfy(ClipoPayloadPolicy.accepts),
                  container.slots.values.allSatisfy(ClipoPayloadPolicy.accepts) else {
                throw ClipoImportError.invalidPayload
            }
            isLoading = true
            settings = container.settings
            history = ClipoHistoryPolicy.pruned(container.history, settings: settings, now: Date())
            slots = normalizedSlots(container.slots)
            isLoading = false
        } catch {
            try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            let backup = storageDirectory.appendingPathComponent("clips-corrupted.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: storageURL, to: backup)
        }
    }

    private func normalizedSlots(_ source: [Int: ClipoItem]) -> [Int: ClipoItem] {
        source.reduce(into: [:]) { result, entry in
            guard (1...9).contains(entry.key) else { return }
            var item = entry.value
            item.slotNumber = entry.key
            result[entry.key] = item
        }
    }

    private func save() {
        guard !isLoading else { return }
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let self else { return }
            saveTask = nil
            enqueueSave()
        }
    }

    private func enqueueSave() {
        let directory = storageDirectory
        let url = storageURL
        let snapshot = ClipoStorageContainer(history: history, slots: slots, settings: settings)
        persistenceQueue.async {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                try encoder.encode(snapshot).write(to: url, options: .atomic)
            } catch {
                Task { @MainActor in
                    ErrorToastManager.shared.show(
                        title: "Clipo",
                        message: String(localized: "clipo.save_failed")
                    )
                }
            }
        }
    }

    private func encodedStore() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(ClipoStorageContainer(history: history, slots: slots, settings: settings))
    }
}
