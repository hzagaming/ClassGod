//
//  HackerDesktopView.swift
//  ClassGod
//
//  Widget Configuration Center — manage Desk Widget data & settings.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct HackerDesktopView: View {
    var onClose: () -> Void
    
    @State private var todoItems: [TodoItem] = []
    @State private var noteContent: String = ""
    @State private var clockCity = String(localized: "hackerdesktop.default_city")
    @State private var weatherCity = String(localized: "hackerdesktop.default_city")
    @State private var cryptoBTC: String = "$64,230 ▲2.4%"
    @State private var cryptoETH: String = "$3,450 ▼0.8%"
    @State private var quoteText = String(localized: "hackerdesktop.default_quote")
    @State private var quoteAuthor: String = "Gene Spafford"
    @State private var asciiArt: String = "  .--.\n /  o \\n|   __|\n \\__/"
    @State private var terminalLogs: [String] = [
        "[14:02:01] kernel: system boot",
        "[14:02:05] sshd: accepted key",
        "[14:03:12] cron: daily backup"
    ]
    @State private var filePaths: [FileItem] = []
    @State private var appItems: [AppLauncherItem] = []
    
    @State private var selectedTab = 0
    @State private var saveTimer: Timer?
    @State private var pendingSaveWorkItem: DispatchWorkItem?
    @State private var isActive = false
    
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    var body: some View {
        VStack(spacing: 0 * zoomScale) {
            // Title bar
            HStack(spacing: 0 * zoomScale) {
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 * zoomScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.close"))
                .padding(.leading, 12 * zoomScale)
                
                Spacer()
                
                Text("hackerdesktop.config_title")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
            }
            .padding(.vertical, 8 * zoomScale)
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Tabs
            HStack(spacing: 0 * zoomScale) {
                TabButton(title: "Data", icon: "cpu", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Tools", icon: "wrench", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Fun", icon: "sparkles", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabButton(title: "Widgets", icon: "square.grid.2x2", isSelected: selectedTab == 3) { selectedTab = 3 }
                TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 4) { selectedTab = 4 }
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.top, 8 * zoomScale)
            
            // Content
            ScrollView {
                VStack(spacing: 16 * zoomScale) {
                    switch selectedTab {
                    case 0: dataTab
                    case 1: toolsTab
                    case 2: funTab
                    case 3: officialWidgetsTab
                    default: aboutTab
                    }
                }
                .padding(14 * zoomScale)
            }
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .onAppear {
            activate()
        }
        .onDisappear {
            deactivate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hackerDesktopWindowDidShow)) { _ in
            activate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hackerDesktopWindowWillHide)) { _ in
            deactivate()
        }
    }
    
    // MARK: - Tabs
    
    private var dataTab: some View {
        VStack(spacing: 14 * zoomScale) {
            ConfigSection(title: "System Monitor", icon: "cpu") {
                Text("hackerdesktop.sync_notice")
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6 * zoomScale) {
                    Image(systemName: WidgetDataStore.shared.usesSharedContainer ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10 * zoomScale))
                    Text(WidgetDataStore.shared.usesSharedContainer ? "hackerdesktop.shared_active" : "hackerdesktop.local_fallback")
                        .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(WidgetDataStore.shared.usesSharedContainer ? .green.opacity(0.75) : .yellow.opacity(0.75))
                
                HStack(spacing: 12 * zoomScale) {
                    StatBadge(label: "CPU", value: "\(Int(SystemMonitor.shared.cpu.total))%", color: .cyan)
                    StatBadge(label: "RAM", value: "\(Int(SystemMonitor.shared.memory.usedPercent * 100))%", color: .green)
                    StatBadge(
                        label: "Battery",
                        value: "\(Int(WidgetMetricNormalization.batteryPercent(from: SystemMonitor.shared.battery.level)))%",
                        color: .orange
                    )
                }
            }
            
            ConfigSection(title: "Clock & Weather", icon: "clock") {
                HStack(spacing: 12 * zoomScale) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("hackerdesktop.clock_city")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("hackerdesktop.city_placeholder", text: $clockCity)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                            .onChange(of: clockCity) { _, _ in saveData() }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("hackerdesktop.weather_city")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("hackerdesktop.city_placeholder", text: $weatherCity)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                            .onChange(of: weatherCity) { _, _ in saveData() }
                    }
                }
            }
        }
    }
    
    private var toolsTab: some View {
        VStack(spacing: 14 * zoomScale) {
            ConfigSection(title: "Todo List", icon: "checkmark.square") {
                VStack(spacing: 6 * zoomScale) {
                    ForEach($todoItems) { $item in
                        HStack(spacing: 8 * zoomScale) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .font(.system(size: 12 * zoomScale))
                                .foregroundStyle(item.isDone ? .green : .white.opacity(0.4))
                                .onTapGesture {
                                    SoundEffectManager.shared.playButtonClick()
                                    HapticManager.shared.generic()
                                    item.isDone.toggle()
                                    saveData(immediate: true)
                                }
                            TextField("hackerdesktop.task_placeholder", text: $item.text)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11 * zoomScale, design: .monospaced))
                                .foregroundStyle(item.isDone ? .white.opacity(0.3) : .white.opacity(0.8))
                                .strikethrough(item.isDone)
                            
                            Button(action: {
                                SoundEffectManager.shared.playWidgetDeleted()
                                HapticManager.shared.warning()
                                todoItems.removeAll { $0.id == item.id }
                                saveData(immediate: true)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9 * zoomScale))
                                    .foregroundStyle(.red.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("button.delete"))
                        }
                    }
                }
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    todoItems.append(TodoItem(id: UUID(), text: "", isDone: false))
                    saveData(immediate: true)
                }) {
                    HStack(spacing: 4 * zoomScale) {
                        Image(systemName: "plus")
                            .font(.system(size: 10 * zoomScale, weight: .bold))
                        Text("hackerdesktop.add_task")
                            .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.cyan)
                    .padding(.vertical, 6 * zoomScale)
                }
                .buttonStyle(.plain)
            }
            
            ConfigSection(title: "Quick Note", icon: "note.text") {
                TextEditor(text: $noteContent)
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                    .frame(height: 100 * zoomScale)
                    .onChange(of: noteContent) { _, _ in saveData() }
            }

            ConfigSection(title: "hackerdesktop.files", icon: "doc.on.doc") {
                ForEach(filePaths) { file in
                    removableWidgetItem(title: file.name, subtitle: file.path) {
                        filePaths.removeAll { $0.id == file.id }
                        saveData(immediate: true)
                    }
                }
                Button("hackerdesktop.add_files", systemImage: "plus") { selectFiles() }
                    .widgetDataButtonStyle(zoomScale: zoomScale)
            }

            ConfigSection(title: "hackerdesktop.apps", icon: "app.badge") {
                ForEach(appItems) { app in
                    removableWidgetItem(title: app.name, subtitle: app.bundleID) {
                        appItems.removeAll { $0.id == app.id }
                        saveData(immediate: true)
                    }
                }
                Button("hackerdesktop.add_apps", systemImage: "plus") { selectApplications() }
                    .widgetDataButtonStyle(zoomScale: zoomScale)
            }
        }
    }
    
    private var funTab: some View {
        VStack(spacing: 14 * zoomScale) {
            ConfigSection(title: "Crypto Prices", icon: "bitcoinsign.circle") {
                HStack(spacing: 12 * zoomScale) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BTC")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("hackerdesktop.price_placeholder", text: $cryptoBTC)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                            .onChange(of: cryptoBTC) { _, _ in saveData() }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ETH")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("hackerdesktop.price_placeholder", text: $cryptoETH)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                            .onChange(of: cryptoETH) { _, _ in saveData() }
                    }
                }
            }
            
            ConfigSection(title: "Hacker Quote", icon: "quote.bubble") {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("hackerdesktop.quote_placeholder", text: $quoteText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8 * zoomScale)
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        .onChange(of: quoteText) { _, _ in saveData() }
                    
                    TextField("hackerdesktop.author_placeholder", text: $quoteAuthor)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(8 * zoomScale)
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        .onChange(of: quoteAuthor) { _, _ in saveData() }
                }
            }
            
            ConfigSection(title: "Terminal Logs", icon: "terminal") {
                VStack(spacing: 4 * zoomScale) {
                    ForEach(terminalLogs.indices, id: \.self) { i in
                        TextField("hackerdesktop.log_line_placeholder", text: $terminalLogs[i])
                            .textFieldStyle(.plain)
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.8))
                            .padding(6 * zoomScale)
                            .background(Color(white: 0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))
                    }
                }
                .onChange(of: terminalLogs) { _, _ in saveData() }
            }
        }
    }

    private var officialWidgetsTab: some View {
        VStack(spacing: 14 * zoomScale) {
            ConfigSection(title: "hackerdesktop.native_widgets.title", icon: "square.grid.2x2") {
                HStack(spacing: 8 * zoomScale) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2 * zoomScale) {
                        Text("hackerdesktop.native_widgets.active")
                            .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        Text("hackerdesktop.native_widgets.description")
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                if !WidgetDataStore.shared.usesSharedContainer {
                    Label("hackerdesktop.native_widgets.local_warning", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.orange.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 7 * zoomScale) {
                    instructionRow(number: 1, text: "hackerdesktop.native_widgets.step1")
                    instructionRow(number: 2, text: "hackerdesktop.native_widgets.step2")
                    instructionRow(number: 3, text: "hackerdesktop.native_widgets.step3")
                }
                .padding(10 * zoomScale)
                .background(Color.white.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

                Button {
                    saveSystemData()
                    SoundEffectManager.shared.playButtonClick()
                } label: {
                    Label("hackerdesktop.native_widgets.refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 10 * zoomScale)
                        .padding(.vertical, 7 * zoomScale)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                }
                .buttonStyle(.plain)
            }

            ConfigSection(title: "hackerdesktop.available_widgets", icon: "square.grid.3x3") {
                let widgets: [(id: String, category: LocalizedStringKey, list: LocalizedStringKey)] = [
                    ("system", "hackerdesktop.widgets.system", "hackerdesktop.widgets.system_list"),
                    ("info", "hackerdesktop.widgets.info", "hackerdesktop.widgets.info_list"),
                    ("tools", "hackerdesktop.widgets.tools", "hackerdesktop.widgets.tools_list"),
                    ("hacker", "hackerdesktop.widgets.hacker", "hackerdesktop.widgets.hacker_list")
                ]
                ForEach(widgets, id: \.id) { item in
                    HStack(alignment: .top, spacing: 8 * zoomScale) {
                        Text(item.category)
                            .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.75))
                            .frame(width: 52 * zoomScale, alignment: .leading)
                        Text(item.list)
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private func instructionRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(spacing: 8 * zoomScale) {
            Text("\(number)")
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .frame(width: 18 * zoomScale, height: 18 * zoomScale)
                .background(Color.cyan)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
    
    private var aboutTab: some View {
        VStack(spacing: 16 * zoomScale) {
            VStack(spacing: 8 * zoomScale) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 40 * zoomScale, weight: .light))
                    .foregroundStyle(.cyan.opacity(0.4))
                
                Text("hackerdesktop.about_title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("hackerdesktop.about_subtitle")
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 10 * zoomScale) {
                Text("hackerdesktop.available_widgets")
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                
                let widgets: [(id: String, category: LocalizedStringKey, list: LocalizedStringKey)] = [
                    ("system", "hackerdesktop.widgets.system", "hackerdesktop.widgets.system_list"),
                    ("info", "hackerdesktop.widgets.info", "hackerdesktop.widgets.info_list"),
                    ("tools", "hackerdesktop.widgets.tools", "hackerdesktop.widgets.tools_list"),
                    ("hacker", "hackerdesktop.widgets.hacker", "hackerdesktop.widgets.hacker_list")
                ]
                
                ForEach(widgets, id: \.id) { item in
                    HStack(alignment: .top, spacing: 8 * zoomScale) {
                        Text(item.category)
                            .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.7))
                            .frame(width: 50 * zoomScale, alignment: .leading)
                        Text(item.list)
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(12 * zoomScale)
            .background(Color(white: 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
            
            Text("hackerdesktop.about_hint")
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .padding(20 * zoomScale)
    }
    
    // MARK: - Data Management

    private func activate() {
        guard !isActive else { return }
        isActive = true
        loadData()
        SystemMonitor.shared.start(interval: 2.0)
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            saveSystemData()
        }
    }

    private func deactivate() {
        guard isActive else { return }
        isActive = false
        SystemMonitor.shared.stop()
        saveTimer?.invalidate()
        saveTimer = nil
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        saveSystemData()
    }
    
    private func saveSystemData() {
        let store = WidgetDataStore.shared
        let disk = SystemMonitor.shared.disks.first
        store.saveSystemSnapshot(
            cpu: SystemMonitor.shared.cpu.total,
            memoryUsed: Double(SystemMonitor.shared.memory.used) / 1024 / 1024 / 1024,
            memoryTotal: Double(SystemMonitor.shared.memory.total) / 1024 / 1024 / 1024,
            diskFree: Double(disk?.free ?? 0) / 1024 / 1024 / 1024,
            diskTotal: Double(disk?.total ?? 0) / 1024 / 1024 / 1024,
            netDown: SystemMonitor.shared.network.downloadSpeedKBs / 1024,
            netUp: SystemMonitor.shared.network.uploadSpeedKBs / 1024,
            battery: WidgetMetricNormalization.batteryPercent(from: SystemMonitor.shared.battery.level),
            isCharging: SystemMonitor.shared.battery.isCharging,
            uptime: Date().timeIntervalSince(SystemMonitor.shared.system.bootTime ?? Date())
        )
        store.set(clockCity, forKey: .clockCity)
        store.set(weatherCity, forKey: .weatherCity)
        store.set("24°", forKey: .weatherTemp)
        store.set("cloud.sun.fill", forKey: .weatherCondition)
        store.setArray(todoItems, forKey: .todoItems)
        store.set(noteContent, forKey: .noteContent)
        store.setArray(filePaths, forKey: .filePaths)
        store.setArray(appItems, forKey: .appBundleIDs)
        store.set(cryptoBTC, forKey: .cryptoBTC)
        store.set(cryptoETH, forKey: .cryptoETH)
        store.set(quoteText, forKey: .quoteText)
        store.set(quoteAuthor, forKey: .quoteAuthor)
        store.set(terminalLogs, forKey: .terminalLogs)
        store.set(asciiArt, forKey: .asciiArt)
        store.reloadAllWidgets()
    }
    
    private func saveData(immediate: Bool = false) {
        pendingSaveWorkItem?.cancel()
        if immediate {
            pendingSaveWorkItem = nil
            saveSystemData()
            return
        }

        let workItem = DispatchWorkItem {
            saveSystemData()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }
    
    private func loadData() {
        let store = WidgetDataStore.shared
        clockCity = store.string(forKey: .clockCity) ?? String(localized: "hackerdesktop.default_city")
        weatherCity = store.string(forKey: .weatherCity) ?? String(localized: "hackerdesktop.default_city")
        todoItems = store.array(forKey: .todoItems, type: TodoItem.self)
        noteContent = store.string(forKey: .noteContent) ?? ""
        filePaths = store.array(forKey: .filePaths, type: FileItem.self)
        appItems = store.array(forKey: .appBundleIDs, type: AppLauncherItem.self)
        cryptoBTC = store.string(forKey: .cryptoBTC) ?? "$64,230 ▲2.4%"
        cryptoETH = store.string(forKey: .cryptoETH) ?? "$3,450 ▼0.8%"
        quoteText = store.string(forKey: .quoteText) ?? String(localized: "hackerdesktop.default_quote")
        quoteAuthor = store.string(forKey: .quoteAuthor) ?? "Gene Spafford"
        terminalLogs = store.stringArray(forKey: .terminalLogs)
        if terminalLogs.isEmpty {
            terminalLogs = [
                "[14:02:01] kernel: system boot",
                "[14:02:05] sshd: accepted key",
                "[14:03:12] cron: daily backup"
            ]
        }
        asciiArt = store.string(forKey: .asciiArt) ?? "  .--.\n /  o \\n|   __|\n \\__/"
    }

    private func removableWidgetItem(title: String, subtitle: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 8 * zoomScale) {
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text(title)
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.delete"))
        }
        .padding(7 * zoomScale)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let existing = Set(filePaths.map(\.path))
        filePaths.append(contentsOf: panel.urls.compactMap { url in
            guard !existing.contains(url.path) else { return nil }
            return FileItem(id: UUID(), path: url.path, name: url.lastPathComponent)
        })
        saveData(immediate: true)
    }

    private func selectApplications() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let existing = Set(appItems.map(\.bundleID))
        appItems.append(contentsOf: panel.urls.compactMap { url in
            guard let bundleID = Bundle(url: url)?.bundleIdentifier,
                  !existing.contains(bundleID) else { return nil }
            return AppLauncherItem(id: UUID(), bundleID: bundleID, name: url.deletingPathExtension().lastPathComponent)
        })
        saveData(immediate: true)
    }
}

// MARK: - Components

private struct TabButton: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let title: LocalizedStringKey
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            action()
        }) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: icon)
                    .font(.system(size: 10 * zoomScale))
                Text(title)
                    .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(isSelected ? .cyan : .white.opacity(0.5))
            .padding(.horizontal, 12 * zoomScale)
            .padding(.vertical, 6 * zoomScale)
            .background(isSelected ? Color.cyan.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1 * zoomScale)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ConfigSection<Content: View>: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            HStack(spacing: 6 * zoomScale) {
                Image(systemName: icon)
                    .font(.system(size: 10 * zoomScale))
                    .foregroundStyle(.cyan.opacity(0.7))
                Text(title)
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
            content
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
    }
}

private struct StatBadge: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let label: LocalizedStringKey
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2 * zoomScale) {
            Text(value)
                .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }
}

private extension View {
    func widgetDataButtonStyle(zoomScale: CGFloat) -> some View {
        buttonStyle(.plain)
            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(.cyan)
            .padding(.horizontal, 9 * zoomScale)
            .padding(.vertical, 6 * zoomScale)
            .background(Color.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }
}

#Preview {
    HackerDesktopView(onClose: {})
        .frame(width: 520, height: 480)
        .background(Color.black)
}
