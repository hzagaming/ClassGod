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
    @State private var searchQuery = ""
    @State private var selectedCategory: ErrorCategory = .all
    @State private var selectedSeverity: ErrorSeverity? = nil
    @State private var selectedEntry: ErrorEntry? = nil
    @State private var searchResults: [ErrorSearchResult] = []
    @State private var isSearching = false
    @State private var showingDetail = false
    @State private var scrollToTop = false
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var displayedEntries: [ErrorEntry] {
        if searchQuery.isEmpty {
            let base = selectedCategory == .all 
                ? ErrorKnowledgeBase.shared.allEntries 
                : ErrorKnowledgeBase.shared.entries(for: selectedCategory)
            if let severity = selectedSeverity {
                return base.filter { $0.severity == severity }
            }
            return base
        } else {
            return searchResults.map { $0.entry }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().allowsHitTesting(false)
            
            VStack(spacing: 0) {
                titleBar
                searchBar
                categoryBar
                severityFilter
                statsBar
                contentArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .sheet(item: $selectedEntry) { entry in
            ErrorDetailView(entry: entry, onDismiss: { selectedEntry = nil })
                .frame(minWidth: 500 * zoomScale, minHeight: 400 * zoomScale)
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
                Text("Error Encyclopedia")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("\(ErrorKnowledgeBase.shared.allEntries.count) errors documented")
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
            
            TextField("Search errors by name, code, or keyword...", text: $searchQuery)
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .onChange(of: searchQuery) { newValue in
                    performSearch(query: newValue)
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
        
            .allowsHitTesting(false))
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
    }
    
    private func performSearch(query: String) {
        if query.isEmpty {
            searchResults = []
            return
        }
        let results = ErrorKnowledgeBase.shared.search(query: query, category: selectedCategory == .all ? nil : selectedCategory)
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
                            ? ErrorKnowledgeBase.shared.allEntries.count
                            : ErrorKnowledgeBase.shared.entries(for: category).count,
                        zoomScale: zoomScale
                    ) {
                        SoundEffectManager.shared.playButtonClick()
                        selectedCategory = category
                        if !searchQuery.isEmpty {
                            performSearch(query: searchQuery)
                        }
                    }
                }
            }
            .padding(.horizontal, 12 * zoomScale)
        }
        .padding(.vertical, 4 * zoomScale)
    }
    
    // MARK: - Severity Filter
    private var severityFilter: some View {
        HStack(spacing: 6 * zoomScale) {
            Text("Severity:")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                selectedSeverity = nil
            }) {
                Text("All")
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
                        Text(severity.rawValue)
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
                    
                        .allowsHitTesting(false))
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
            Text("\(displayedEntries.count) error\(displayedEntries.count == 1 ? "" : "s")")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            
            Spacer()
            
            if !searchQuery.isEmpty {
                Text("Searching: \"\(searchQuery)\"")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        ScrollView(showsIndicators: false) {
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
                Text(category.rawValue)
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
            
                .allowsHitTesting(false))
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
                    
                    Text(entry.severity.rawValue)
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
                        
                        Text(entry.category.rawValue)
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
            
                .allowsHitTesting(false))
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
