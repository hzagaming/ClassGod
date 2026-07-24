//
//  ErrorHubView.swift
//  ClassGod
//
//  Comprehensive Error Encyclopedia Browser
//  Created by ClassGod on 2026/05/31.
//

import SwiftUI

// MARK: - Error Hub View
struct ErrorHubView: View {
    var onClose: () -> Void
    
    @ObservedObject private var prefs = PreferencesManager.shared
    @ObservedObject private var navState = ErrorHubNavigationState.shared
    @ObservedObject private var knowledgeBase = ErrorKnowledgeBase.shared
    @State private var searchQuery = ""
    @State private var selectedCategory: ErrorCategory = .all
    @State private var selectedSeverity: ErrorSeverity? = nil
    @State private var selectedTag: String? = nil
    @State private var selectedEntry: ErrorEntry? = nil
    @State private var searchResults: [ErrorSearchResult] = []
    @State private var pendingNavID: UUID? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    // Base entries after category/severity/tag filtering (excluding search)
    private var baseEntries: [ErrorEntry] {
        let catFiltered = selectedCategory == .all
            ? knowledgeBase.allEntries
            : knowledgeBase.entries(for: selectedCategory)
        let sevFiltered: [ErrorEntry]
        if let severity = selectedSeverity {
            sevFiltered = catFiltered.filter { $0.severity == severity }
        } else {
            sevFiltered = catFiltered
        }
        if let tag = selectedTag {
            return sevFiltered.filter { $0.tags.contains(tag) }
        }
        return sevFiltered
    }
    
    private var displayedEntries: [ErrorEntry] {
        if searchQuery.isEmpty {
            return baseEntries
        } else {
            return searchResults.map { $0.entry }
        }
    }
    
    // Grouped by category when showing all without search/tag filter
    private var groupedEntries: [(category: ErrorCategory, entries: [ErrorEntry])]? {
        guard searchQuery.isEmpty, selectedCategory == .all, selectedTag == nil else { return nil }
        let cats = ErrorCategory.allCases.filter { $0 != .all }
        return cats.compactMap { cat in
            let entries = displayedEntries.filter { $0.category == cat }
            return entries.isEmpty ? nil : (cat, entries)
        }
    }
    
    // Popular tags from current base entries
    private var availableTags: [String] {
        let allTags = baseEntries.flatMap { $0.tags }
        var counts: [String: Int] = [:]
        for tag in allTags { counts[tag, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.prefix(16).map { $0.key }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().allowsHitTesting(false)
            
            VStack(spacing: 0 * zoomScale) {
                titleBar
                searchBar
                categoryBar
                tagBar
                severityFilter
                statsBar
                contentArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .sheet(item: $selectedEntry) { entry in
            ErrorDetailView(entry: entry, onDismiss: { selectedEntry = nil })
                .frame(minWidth: 500 * zoomScale, minHeight: 400 * zoomScale)
        }
        .onAppear {
            knowledgeBase.ensureLoaded()
        }
        .onChange(of: navState.targetEntryID, initial: true) { _, newID in
            guard let id = newID else { return }
            if let entry = knowledgeBase.entry(withID: id) {
                selectedCategory = .all
                searchQuery = ""
                selectedTag = nil
                selectedSeverity = nil
                selectedEntry = entry
                pendingNavID = nil
            } else {
                pendingNavID = id
            }
            navState.clearTarget()
        }
        .onChange(of: knowledgeBase.allEntries) { _, _ in
            if let id = pendingNavID, let entry = knowledgeBase.entry(withID: id) {
                selectedCategory = .all
                searchQuery = ""
                selectedTag = nil
                selectedSeverity = nil
                selectedEntry = entry
                pendingNavID = nil
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            if !searchQuery.isEmpty { debouncedSearch(query: searchQuery) }
        }
        .onChange(of: selectedSeverity) { _, _ in
            if !searchQuery.isEmpty { debouncedSearch(query: searchQuery) }
        }
        .onChange(of: selectedTag) { _, _ in
            if !searchQuery.isEmpty { debouncedSearch(query: searchQuery) }
        }
    }
    
    // MARK: - Title Bar
    private var titleBar: some View {
        HStack(spacing: 0) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
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
            .padding(.leading, 12 * zoomScale)
            
            Spacer()
            
            VStack(spacing: 0 * zoomScale) {
                Text("error.hub_title")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(String(format: String(localized: "error.documented_count"), knowledgeBase.allEntries.count))
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            Spacer()
            
            Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
        }
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.03))
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12 * zoomScale))
                .foregroundStyle(.white.opacity(0.4))
            
            TextField(String(localized: "error.search_placeholder"), text: $searchQuery)
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .onChange(of: searchQuery) { _, newValue in
                    debouncedSearch(query: newValue)
                }
            
            if !searchQuery.isEmpty {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    searchQuery = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12 * zoomScale))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8 * zoomScale)
        .background(Color(white: 0.06))
        .cornerRadius(8 * zoomScale)
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
    }
    
    private func debouncedSearch(query: String) {
        searchTask?.cancel()
        if query.isEmpty {
            searchResults = []
            return
        }
        let kb = knowledgeBase
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000) // 150 ms debounce
            guard !Task.isCancelled else { return }
            await performSearch(query: query, knowledgeBase: kb)
        }
    }
    
    @MainActor
    private func performSearch(query: String, knowledgeBase: ErrorKnowledgeBase) async {
        if query.isEmpty {
            searchResults = []
            return
        }
        let category = selectedCategory
        let severity = selectedSeverity
        let tag = selectedTag
        
        var results = knowledgeBase.search(
            query: query,
            category: category == .all ? nil : category
        )
        if let severity = severity {
            results = results.filter { $0.entry.severity == severity }
        }
        if let tag = tag {
            results = results.filter { $0.entry.tags.contains(tag) }
        }
        
        guard searchQuery == query else { return }
        searchResults = results
    }
    
    // MARK: - Category Bar
    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6 * zoomScale) {
                ForEach(ErrorCategory.allCases) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: category == .all
                            ? knowledgeBase.allEntries.count
                            : knowledgeBase.entries(for: category).count,
                        zoomScale: zoomScale
                    ) {
                        SoundEffectManager.shared.playButtonClick()
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 12 * zoomScale)
        }
        .padding(.vertical, 4 * zoomScale)
    }
    
    // MARK: - Tag Bar
    private var tagBar: some View {
        VStack(spacing: 0 * zoomScale) {
            if !availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6 * zoomScale) {
                        if selectedTag != nil {
                            Button(action: {
                                SoundEffectManager.shared.playButtonClick()
                                selectedTag = nil
                            }) {
                                HStack(spacing: 3 * zoomScale) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 9 * zoomScale))
                                    Text("button.clear")
                                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                                }
                                .foregroundStyle(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ForEach(availableTags, id: \.self) { tag in
                            TagPill(
                                tag: tag,
                                isSelected: selectedTag == tag,
                                zoomScale: zoomScale
                            ) {
                                SoundEffectManager.shared.playButtonClick()
                                selectedTag = selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, 12 * zoomScale)
                }
                .padding(.vertical, 4 * zoomScale)
            }
        }
    }
    
    // MARK: - Severity Filter
    private var severityFilter: some View {
        HStack(spacing: 6 * zoomScale) {
            Text("error.severity_label")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                selectedSeverity = nil
            }) {
                Text("permission.category.all")
                    .font(.system(size: 9 * zoomScale, weight: selectedSeverity == nil ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(selectedSeverity == nil ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 8 * zoomScale)
                    .padding(.vertical, 3 * zoomScale)
                    .background(selectedSeverity == nil ? Color.white.opacity(0.15) : Color.clear)
                    .cornerRadius(4 * zoomScale)
            }
            .buttonStyle(.plain)
            
            ForEach(ErrorSeverity.allCases, id: \.self) { severity in
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    selectedSeverity = selectedSeverity == severity ? nil : severity
                }) {
                    HStack(spacing: 3 * zoomScale) {
                        Circle()
                            .fill(Color(hex: severity.colorHex))
                            .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                        Text(severity.displayName)
                            .font(.system(size: 9 * zoomScale, weight: selectedSeverity == severity ? .bold : .regular, design: .monospaced))
                    }
                    .foregroundStyle(selectedSeverity == severity ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 8 * zoomScale)
                    .padding(.vertical, 3 * zoomScale)
                    .background(selectedSeverity == severity ? Color(hex: severity.colorHex).opacity(0.2) : Color.clear)
                    .cornerRadius(4 * zoomScale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(selectedSeverity == severity ? Color(hex: severity.colorHex).opacity(0.5) : Color.clear, lineWidth: 1 * zoomScale)
                            .allowsHitTesting(false)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
    }
    
    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack {
            Text(String(format: String(localized: "error.result_count"), displayedEntries.count))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            
            Spacer()
            
            if !searchQuery.isEmpty {
                Text(String(format: String(localized: "error.searching"), searchQuery))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            } else if let tag = selectedTag {
                Text(String(format: String(localized: "error.tag_filter"), tag))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                if let groups = groupedEntries {
                    LazyVStack(spacing: 16 * zoomScale) {
                        ForEach(groups, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 8 * zoomScale) {
                                sectionHeader(for: group.category)
                                LazyVStack(spacing: 6 * zoomScale) {
                                    ForEach(group.entries) { entry in
                                        ErrorRowView(entry: entry, zoomScale: zoomScale) {
                                            SoundEffectManager.shared.playButtonClick()
                                            selectedEntry = entry
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                } else {
                    LazyVStack(spacing: 6 * zoomScale) {
                        ForEach(displayedEntries) { entry in
                            ErrorRowView(entry: entry, zoomScale: zoomScale) {
                                SoundEffectManager.shared.playButtonClick()
                                selectedEntry = entry
                            }
                        }
                    }
                    .padding(.horizontal, 12 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                }
            }
            
            if knowledgeBase.isLoading && knowledgeBase.allEntries.isEmpty {
                loadingOverlay
            } else if let error = knowledgeBase.loadingError {
                errorOverlay(message: error)
            }
        }
    }
    
    private var loadingOverlay: some View {
        VStack(spacing: 10 * zoomScale) {
            ProgressView()
                .scaleEffect(0.8 * zoomScale)
                .tint(.white.opacity(0.6))
            Text("error.loading")
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 10 * zoomScale) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 20 * zoomScale))
                .foregroundStyle(.orange)
            Text("error.load_failed")
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20 * zoomScale)
            Button(String(localized: "button.retry")) {
                knowledgeBase.ensureLoaded()
            }
            .font(.system(size: 10 * zoomScale, design: .monospaced))
            .padding(.horizontal, 14 * zoomScale)
            .padding(.vertical, 5 * zoomScale)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4 * zoomScale)
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
    
    private func sectionHeader(for category: ErrorCategory) -> some View {
        HStack(spacing: 6 * zoomScale) {
            Image(systemName: category.icon)
                .font(.system(size: 10 * zoomScale))
                .foregroundStyle(.white.opacity(0.6))
            Text(category.displayName)
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
            Text("\(knowledgeBase.entries(for: category).count)")
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 5 * zoomScale)
                .padding(.vertical, 1 * zoomScale)
                .background(Color(white: 0.1))
                .cornerRadius(3 * zoomScale)
            Spacer()
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let category: ErrorCategory
    let isSelected: Bool
    let count: Int
    let zoomScale: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: category.icon)
                    .font(.system(size: 9 * zoomScale))
                Text(category.displayName)
                    .font(.system(size: 9 * zoomScale, weight: isSelected ? .bold : .medium, design: .monospaced))
                Text("\(count)")
                    .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 10 * zoomScale)
            .padding(.vertical, 5 * zoomScale)
            .background(isSelected ? Color.white.opacity(0.12) : Color(white: 0.05))
            .cornerRadius(6 * zoomScale)
            .overlay(
                RoundedRectangle(cornerRadius: 6 * zoomScale)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1 * zoomScale)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Pill
struct TagPill: View {
    let tag: String
    let isSelected: Bool
    let zoomScale: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.system(size: 8 * zoomScale, weight: isSelected ? .bold : .regular, design: .monospaced))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 8 * zoomScale)
                .padding(.vertical, 3 * zoomScale)
                .background(isSelected ? .cyan.opacity(0.2) : Color(white: 0.05))
                .cornerRadius(4 * zoomScale)
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(isSelected ? .cyan.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1 * zoomScale)
                        .allowsHitTesting(false)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Error Row View
struct ErrorRowView: View {
    let entry: ErrorEntry
    let zoomScale: CGFloat
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10 * zoomScale) {
                // Severity indicator
                VStack(spacing: 2 * zoomScale) {
                    Image(systemName: entry.severity.icon)
                        .font(.system(size: 14 * zoomScale))
                        .foregroundStyle(Color(hex: entry.severity.colorHex))
                    
                    Text(entry.severity.displayName)
                        .font(.system(size: 7 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: entry.severity.colorHex))
                }
                .frame(width: 50 * zoomScale)
                
                VStack(alignment: .leading, spacing: 3 * zoomScale) {
                    HStack(spacing: 6 * zoomScale) {
                        Text(entry.title)
                            .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if let code = entry.errorCode {
                            Text(code)
                                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 5 * zoomScale)
                                .padding(.vertical, 1 * zoomScale)
                                .background(Color(white: 0.1))
                                .cornerRadius(3 * zoomScale)
                        }
                    }
                    
                    Text(entry.description)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4 * zoomScale) {
                        ForEach(entry.tags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 7 * zoomScale, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .padding(.horizontal, 4 * zoomScale)
                                .padding(.vertical, 1 * zoomScale)
                                .background(Color(white: 0.08))
                                .cornerRadius(2 * zoomScale)
                        }
                        
                        Spacer()
                        
                        Text(entry.category.displayName)
                            .font(.system(size: 7 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10 * zoomScale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(10 * zoomScale)
            .background(isHovered ? Color(white: 0.06) : Color(white: 0.03))
            .cornerRadius(8 * zoomScale)
            .overlay(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .stroke(isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.05), lineWidth: 1 * zoomScale)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Window Wrapper
struct ErrorHubWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        ErrorHubView(onClose: onClose)
    }
}
