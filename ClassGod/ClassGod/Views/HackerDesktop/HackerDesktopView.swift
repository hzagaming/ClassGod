//
//  HackerDesktopView.swift
//  ClassGod
//
//  Widget Configuration Center — manage Desk Widget data & settings.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

nonisolated enum HackerDesktopTab: Int, CaseIterable {
    case data
    case tools
    case fun
    case widgets
    case about

    static let defaultSelection: HackerDesktopTab = .widgets
}

struct HackerDesktopView: View {
    var onClose: () -> Void
    
    @State private var todoItems: [TodoItem] = []
    @State private var noteContent: String = ""
    @State private var clockCity = String(localized: "hackerdesktop.default_city")
    @State private var weatherCity = String(localized: "hackerdesktop.default_city")
    @State private var weatherTemperature = 24.0
    @State private var weatherApparentTemperature = 25.0
    @State private var weatherHigh = 28.0
    @State private var weatherLow = 19.0
    @State private var weatherHumidity = 62
    @State private var weatherCondition = WidgetWeatherCondition.partlyCloudy
    @State private var weatherUnit = WidgetTemperatureUnit.celsius
    @State private var weatherUpdatedAt = Date()
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
    
    @State private var selectedTab = HackerDesktopTab.defaultSelection
    @State private var pendingSaveWorkItem: DispatchWorkItem?
    @State private var pendingReloadKinds = Set<ClassGodWidgetKind>()
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
                TabButton(title: "Data", icon: "cpu", isSelected: selectedTab == .data) { selectedTab = .data }
                TabButton(title: "Tools", icon: "wrench", isSelected: selectedTab == .tools) { selectedTab = .tools }
                TabButton(title: "Fun", icon: "sparkles", isSelected: selectedTab == .fun) { selectedTab = .fun }
                TabButton(title: "Widgets", icon: "square.grid.2x2", isSelected: selectedTab == .widgets) { selectedTab = .widgets }
                TabButton(title: "About", icon: "info.circle", isSelected: selectedTab == .about) { selectedTab = .about }
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.top, 8 * zoomScale)
            
            // Content
            ScrollView {
                VStack(spacing: 16 * zoomScale) {
                    switch selectedTab {
                    case .data: dataTab
                    case .tools: toolsTab
                    case .fun: funTab
                    case .widgets: officialWidgetsTab
                    case .about: aboutTab
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
                            .onChange(of: clockCity) { _, _ in
                                saveData(for: [.clock, .worldClock])
                            }
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
                            .onChange(of: weatherCity) { _, _ in weatherChanged() }
                    }
                }

                HStack(spacing: 12 * zoomScale) {
                    weatherNumberField("hackerdesktop.weather_temperature", value: $weatherTemperature)
                        .onChange(of: weatherTemperature) { _, _ in weatherChanged() }
                    weatherNumberField("hackerdesktop.weather_feels_like", value: $weatherApparentTemperature)
                        .onChange(of: weatherApparentTemperature) { _, _ in weatherChanged() }
                    weatherNumberField("hackerdesktop.weather_high", value: $weatherHigh)
                        .onChange(of: weatherHigh) { _, _ in weatherChanged() }
                    weatherNumberField("hackerdesktop.weather_low", value: $weatherLow)
                        .onChange(of: weatherLow) { _, _ in weatherChanged() }
                }

                HStack(spacing: 12 * zoomScale) {
                    VStack(alignment: .leading, spacing: 4 * zoomScale) {
                        Text("hackerdesktop.weather_condition")
                            .widgetFieldLabel(zoomScale: zoomScale)
                        Picker("hackerdesktop.weather_condition", selection: $weatherCondition) {
                            ForEach(WidgetWeatherCondition.allCases, id: \.self) { condition in
                                Label(weatherConditionTitle(condition), systemImage: condition.rawValue)
                                    .tag(condition)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: weatherCondition) { _, _ in weatherChanged() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4 * zoomScale) {
                        Text("hackerdesktop.weather_unit")
                            .widgetFieldLabel(zoomScale: zoomScale)
                        Picker("hackerdesktop.weather_unit", selection: $weatherUnit) {
                            ForEach(WidgetTemperatureUnit.allCases, id: \.self) { unit in
                                Text(verbatim: unit.symbol).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .onChange(of: weatherUnit) { oldValue, newValue in
                            changeWeatherUnit(from: oldValue, to: newValue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4 * zoomScale) {
                        Text("hackerdesktop.weather_humidity")
                            .widgetFieldLabel(zoomScale: zoomScale)
                        Stepper(value: $weatherHumidity, in: 0...100) {
                            Text(verbatim: "\(weatherHumidity)%")
                                .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .onChange(of: weatherHumidity) { _, _ in weatherChanged() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 5 * zoomScale) {
                    Image(systemName: "info.circle")
                    Text("hackerdesktop.weather_manual_notice")
                    Spacer()
                    Text("hackerdesktop.weather_updated")
                    Text(weatherUpdatedAt, style: .relative)
                }
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
    
    private var toolsTab: some View {
        VStack(spacing: 14 * zoomScale) {
            ConfigSection(title: "Todo List", icon: "checkmark.square") {
                VStack(spacing: 6 * zoomScale) {
                    ForEach($todoItems) { $item in
                        HStack(spacing: 8 * zoomScale) {
                            Button {
                                SoundEffectManager.shared.playButtonClick()
                                HapticManager.shared.generic()
                                item.isDone.toggle()
                                saveData(for: [.todo], immediate: true)
                            } label: {
                                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 12 * zoomScale))
                                    .foregroundStyle(item.isDone ? .green : .white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                item.isDone ? Text("hackerdesktop.mark_pending") : Text("hackerdesktop.mark_done")
                            )
                            TextField("hackerdesktop.task_placeholder", text: $item.text)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11 * zoomScale, design: .monospaced))
                                .foregroundStyle(item.isDone ? .white.opacity(0.3) : .white.opacity(0.8))
                                .strikethrough(item.isDone)
                                .onChange(of: item.text) { _, _ in saveData(for: [.todo]) }
                            
                            Button(action: {
                                SoundEffectManager.shared.playWidgetDeleted()
                                HapticManager.shared.warning()
                                todoItems.removeAll { $0.id == item.id }
                                saveData(for: [.todo], immediate: true)
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
                    guard todoItems.count < WidgetContentPolicy.maxTodoItems else { return }
                    todoItems.append(TodoItem(id: UUID(), text: "", isDone: false))
                    saveData(for: [.todo], immediate: true)
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
                .disabled(todoItems.count >= WidgetContentPolicy.maxTodoItems)
            }
            
            ConfigSection(title: "Quick Note", icon: "note.text") {
                TextEditor(text: $noteContent)
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                    .frame(height: 100 * zoomScale)
                    .onChange(of: noteContent) { _, _ in saveData(for: [.notes]) }
            }

            ConfigSection(title: "hackerdesktop.files", icon: "doc.on.doc") {
                ForEach(filePaths) { file in
                    removableWidgetItem(title: file.name, subtitle: file.path) {
                        filePaths.removeAll { $0.id == file.id }
                        saveData(for: [.files], immediate: true)
                    }
                }
                Button("hackerdesktop.add_files", systemImage: "plus") { selectFiles() }
                    .widgetDataButtonStyle(zoomScale: zoomScale)
            }

            ConfigSection(title: "hackerdesktop.apps", icon: "app.badge") {
                ForEach(appItems) { app in
                    removableWidgetItem(title: app.name, subtitle: app.bundleID) {
                        appItems.removeAll { $0.id == app.id }
                        saveData(for: [.appLauncher], immediate: true)
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
                            .onChange(of: cryptoBTC) { _, _ in saveData(for: [.crypto]) }
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
                            .onChange(of: cryptoETH) { _, _ in saveData(for: [.crypto]) }
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
                        .onChange(of: quoteText) { _, _ in saveData(for: [.quote]) }
                    
                    TextField("hackerdesktop.author_placeholder", text: $quoteAuthor)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(8 * zoomScale)
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        .onChange(of: quoteAuthor) { _, _ in saveData(for: [.quote]) }
                }
            }
            
            ConfigSection(title: "Terminal Logs", icon: "terminal") {
                VStack(spacing: 4 * zoomScale) {
                    ForEach(terminalLogs.indices, id: \.self) { index in
                        HStack(spacing: 6 * zoomScale) {
                            TextField("hackerdesktop.log_line_placeholder", text: $terminalLogs[index])
                                .textFieldStyle(.plain)
                                .font(.system(size: 10 * zoomScale, design: .monospaced))
                                .foregroundStyle(.green.opacity(0.8))
                                .padding(6 * zoomScale)
                                .background(Color(white: 0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))
                            Button {
                                terminalLogs.remove(at: index)
                                saveData(for: [.terminal], immediate: true)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.65))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("button.delete"))
                        }
                    }
                }
                .onChange(of: terminalLogs) { _, _ in saveData(for: [.terminal]) }

                Button("hackerdesktop.add_log_line", systemImage: "plus") {
                    guard terminalLogs.count < WidgetContentPolicy.maxLogLines else { return }
                    terminalLogs.append("")
                    saveData(for: [.terminal], immediate: true)
                }
                .widgetDataButtonStyle(zoomScale: zoomScale)
                .disabled(terminalLogs.count >= WidgetContentPolicy.maxLogLines)
            }

            ConfigSection(title: "hackerdesktop.ascii_art", icon: "textformat") {
                TextEditor(text: $asciiArt)
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.75))
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                    .frame(height: 110 * zoomScale)
                    .onChange(of: asciiArt) { _, _ in saveData(for: [.asciiArt]) }
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
                    refreshAllWidgets()
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
        loadData()
        isActive = true
        SystemMonitor.shared.start(client: .hackerDesktop, interval: 2.0)
        saveSystemData()
    }

    private func deactivate() {
        guard isActive else { return }
        isActive = false
        SystemMonitor.shared.stop(client: .hackerDesktop)
        persistPendingData()
        saveSystemData(reloadWidgets: false)
    }
    
    private func saveSystemData(reloadWidgets: Bool = true) {
        WidgetHostSnapshot.save(reloadWidgets: reloadWidgets)
    }
    
    private func saveData(for kinds: [ClassGodWidgetKind], immediate: Bool = false) {
        guard isActive else { return }
        pendingReloadKinds.formUnion(kinds)
        pendingSaveWorkItem?.cancel()
        if immediate {
            persistPendingData()
            return
        }

        let workItem = DispatchWorkItem {
            persistPendingData()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func persistPendingData() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        let kinds = pendingReloadKinds
        pendingReloadKinds.removeAll()
        guard !kinds.isEmpty else { return }
        persistConfiguredData()
        WidgetDataStore.shared.reloadWidgets(Array(kinds))
    }

    private func persistConfiguredData() {
        let store = WidgetDataStore.shared
        store.set(
            WidgetContentPolicy.text(clockCity, maxLength: WidgetContentPolicy.maxCityLength, trimsWhitespace: true),
            forKey: .clockCity
        )
        store.setValue(WidgetWeatherPolicy.normalized(currentWeatherSnapshot), forKey: .weatherSnapshot)
        store.setArray(WidgetContentPolicy.todoItems(todoItems), forKey: .todoItems)
        store.set(WidgetContentPolicy.text(noteContent, maxLength: WidgetContentPolicy.maxNoteLength), forKey: .noteContent)
        store.setArray(WidgetContentPolicy.fileItems(filePaths), forKey: .filePaths)
        store.setArray(WidgetContentPolicy.appItems(appItems), forKey: .appBundleIDs)
        store.set(WidgetContentPolicy.text(cryptoBTC, maxLength: WidgetContentPolicy.maxPriceLength, trimsWhitespace: true), forKey: .cryptoBTC)
        store.set(WidgetContentPolicy.text(cryptoETH, maxLength: WidgetContentPolicy.maxPriceLength, trimsWhitespace: true), forKey: .cryptoETH)
        store.set(WidgetContentPolicy.text(quoteText, maxLength: WidgetContentPolicy.maxQuoteLength, trimsWhitespace: true), forKey: .quoteText)
        store.set(WidgetContentPolicy.text(quoteAuthor, maxLength: WidgetContentPolicy.maxAuthorLength, trimsWhitespace: true), forKey: .quoteAuthor)
        store.set(WidgetContentPolicy.terminalLogs(terminalLogs), forKey: .terminalLogs)
        store.set(WidgetContentPolicy.text(asciiArt, maxLength: WidgetContentPolicy.maxAsciiLength), forKey: .asciiArt)
    }

    private func refreshAllWidgets() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        pendingReloadKinds.removeAll()
        persistConfiguredData()
        saveSystemData(reloadWidgets: false)
        WidgetDataStore.shared.reloadAllWidgets()
    }
    
    private func loadData() {
        let store = WidgetDataStore.shared
        clockCity = WidgetContentPolicy.text(
            store.string(forKey: .clockCity) ?? String(localized: "hackerdesktop.default_city"),
            maxLength: WidgetContentPolicy.maxCityLength,
            trimsWhitespace: true
        )
        let weather = WidgetWeatherPolicy.normalized(
            store.value(forKey: .weatherSnapshot, type: WidgetWeatherSnapshot.self) ?? defaultWeatherSnapshot
        )
        weatherCity = weather.city
        weatherTemperature = weather.temperature
        weatherApparentTemperature = weather.apparentTemperature
        weatherHigh = weather.high
        weatherLow = weather.low
        weatherHumidity = weather.humidity
        weatherCondition = weather.condition
        weatherUnit = weather.unit
        weatherUpdatedAt = weather.updatedAt
        todoItems = WidgetContentPolicy.todoItems(store.array(forKey: .todoItems, type: TodoItem.self))
        noteContent = WidgetContentPolicy.text(
            store.string(forKey: .noteContent) ?? "",
            maxLength: WidgetContentPolicy.maxNoteLength
        )
        filePaths = WidgetContentPolicy.fileItems(store.array(forKey: .filePaths, type: FileItem.self))
        appItems = WidgetContentPolicy.appItems(store.array(forKey: .appBundleIDs, type: AppLauncherItem.self))
        cryptoBTC = store.string(forKey: .cryptoBTC) ?? "$64,230 ▲2.4%"
        cryptoETH = store.string(forKey: .cryptoETH) ?? "$3,450 ▼0.8%"
        quoteText = store.string(forKey: .quoteText) ?? String(localized: "hackerdesktop.default_quote")
        quoteAuthor = store.string(forKey: .quoteAuthor) ?? "Gene Spafford"
        if store.contains(.terminalLogs) {
            terminalLogs = WidgetContentPolicy.terminalLogs(store.stringArray(forKey: .terminalLogs))
        } else {
            terminalLogs = [
                "[14:02:01] kernel: system boot",
                "[14:02:05] sshd: accepted key",
                "[14:03:12] cron: daily backup"
            ]
        }
        asciiArt = WidgetContentPolicy.text(
            store.string(forKey: .asciiArt) ?? "  .--.\n /  o \\n|   __|\n \\__/",
            maxLength: WidgetContentPolicy.maxAsciiLength
        )
    }

    private var defaultWeatherSnapshot: WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            city: String(localized: "hackerdesktop.default_city"),
            temperature: 24,
            apparentTemperature: 25,
            high: 28,
            low: 19,
            humidity: 62,
            condition: .partlyCloudy,
            unit: .celsius,
            updatedAt: Date()
        )
    }

    private var currentWeatherSnapshot: WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            city: weatherCity,
            temperature: weatherTemperature,
            apparentTemperature: weatherApparentTemperature,
            high: weatherHigh,
            low: weatherLow,
            humidity: weatherHumidity,
            condition: weatherCondition,
            unit: weatherUnit,
            updatedAt: weatherUpdatedAt
        )
    }

    private func weatherChanged() {
        guard isActive else { return }
        weatherUpdatedAt = Date()
        saveData(for: [.weather])
    }

    private func changeWeatherUnit(from source: WidgetTemperatureUnit, to destination: WidgetTemperatureUnit) {
        guard source != destination, isActive else { return }
        weatherTemperature = WidgetWeatherPolicy.convert(weatherTemperature, from: source, to: destination)
        weatherApparentTemperature = WidgetWeatherPolicy.convert(weatherApparentTemperature, from: source, to: destination)
        weatherHigh = WidgetWeatherPolicy.convert(weatherHigh, from: source, to: destination)
        weatherLow = WidgetWeatherPolicy.convert(weatherLow, from: source, to: destination)
        weatherChanged()
    }

    private func weatherNumberField(_ title: LocalizedStringKey, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4 * zoomScale) {
            Text(title)
                .widgetFieldLabel(zoomScale: zoomScale)
            TextField(
                "hackerdesktop.weather_value_placeholder",
                value: value,
                format: .number.precision(.fractionLength(0...1))
            )
            .textFieldStyle(.plain)
            .font(.system(size: 11 * zoomScale, design: .monospaced))
            .foregroundStyle(.white)
            .padding(8 * zoomScale)
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        }
        .frame(maxWidth: .infinity)
    }

    private func weatherConditionTitle(_ condition: WidgetWeatherCondition) -> LocalizedStringKey {
        switch condition {
        case .clearDay: "weather.condition.clear"
        case .clearNight: "weather.condition.clear_night"
        case .partlyCloudy: "weather.condition.partly_cloudy"
        case .cloudy: "weather.condition.cloudy"
        case .rain: "weather.condition.rain"
        case .thunderstorm: "weather.condition.storm"
        case .snow: "weather.condition.snow"
        case .fog: "weather.condition.fog"
        case .wind: "weather.condition.wind"
        }
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
        var existing = Set(filePaths.map(\.path))
        let availableSlots = max(0, WidgetContentPolicy.maxFileItems - filePaths.count)
        filePaths.append(contentsOf: panel.urls.compactMap { url in
            guard existing.insert(url.path).inserted else { return nil }
            return FileItem(id: UUID(), path: url.path, name: url.lastPathComponent)
        }.prefix(availableSlots))
        saveData(for: [.files], immediate: true)
    }

    private func selectApplications() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        var existing = Set(appItems.map(\.bundleID))
        let availableSlots = max(0, WidgetContentPolicy.maxAppItems - appItems.count)
        appItems.append(contentsOf: panel.urls.compactMap { url in
            guard let bundleID = Bundle(url: url)?.bundleIdentifier,
                  existing.insert(bundleID).inserted else { return nil }
            return AppLauncherItem(id: UUID(), bundleID: bundleID, name: url.deletingPathExtension().lastPathComponent)
        }.prefix(availableSlots))
        saveData(for: [.appLauncher], immediate: true)
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
    func widgetFieldLabel(zoomScale: CGFloat) -> some View {
        font(.system(size: 9 * zoomScale, design: .monospaced))
            .foregroundStyle(.white.opacity(0.4))
    }

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
