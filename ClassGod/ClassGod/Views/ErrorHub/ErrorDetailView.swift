//
//  ErrorDetailView.swift
//  ClassGod
//
//  Error Detail Modal / Popup View
//  Created by ClassGod on 2026/05/31.
//

import SwiftUI

struct ErrorDetailView: View {
    let entry: ErrorEntry
    var onDismiss: () -> Void
    
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var selectedSolutionIndex: Int? = nil
    @State private var selectedCodeExample: CodeExample? = nil
    @State private var copiedCode = false
    @State private var showRelated = false
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0 * zoomScale) {
                    headerSection
                    Divider().background(Color.white.opacity(0.1))
                    descriptionSection
                    Divider().background(Color.white.opacity(0.1))
                    causeSection
                    Divider().background(Color.white.opacity(0.1))
                    solutionsSection
                    Divider().background(Color.white.opacity(0.1))
                    codeExamplesSection
                    Divider().background(Color.white.opacity(0.1))
                    relatedErrorsSection
                    Divider().background(Color.white.opacity(0.1))
                    metaSection
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8 * zoomScale) {
            HStack(spacing: 0 * zoomScale) {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    onDismiss()
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
                
                Text("error.detail_title")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
            }
            
            // Severity badge
            HStack(spacing: 6 * zoomScale) {
                Image(systemName: entry.severity.icon)
                    .font(.system(size: 14 * zoomScale))
                    .foregroundStyle(Color(hex: entry.severity.colorHex))
                Text(entry.severity.displayName.uppercased())
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: entry.severity.colorHex))
            }
            .padding(.horizontal, 12 * zoomScale)
            .padding(.vertical, 4 * zoomScale)
            .background(Color(hex: entry.severity.colorHex).opacity(0.1))
            .cornerRadius(4 * zoomScale)
            .overlay(
                RoundedRectangle(cornerRadius: 4 * zoomScale)
                    .stroke(Color(hex: entry.severity.colorHex).opacity(0.3), lineWidth: 1 * zoomScale)
            
                .allowsHitTesting(false))
            
            // Title
            Text(entry.title)
                .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16 * zoomScale)
            
            // Error code
            if let code = entry.errorCode {
                HStack(spacing: 4 * zoomScale) {
                    Text("error.code_label")
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(code)
                        .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 10 * zoomScale)
                .padding(.vertical, 3 * zoomScale)
                .background(Color(white: 0.08))
                .cornerRadius(3 * zoomScale)
            }
            
            // Category & tags
            HStack(spacing: 6 * zoomScale) {
                HStack(spacing: 3 * zoomScale) {
                    Image(systemName: entry.category.icon)
                        .font(.system(size: 8 * zoomScale))
                    Text(entry.category.displayName)
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.5))
                
                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 7 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 4 * zoomScale)
                        .padding(.vertical, 1 * zoomScale)
                        .background(Color(white: 0.08))
                        .cornerRadius(2 * zoomScale)
                }
            }
            
            // Open in Encyclopedia
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                ErrorHubNavigationState.shared.navigateToEntry(id: entry.id)
            }) {
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 8 * zoomScale))
                    Text(String(localized: "error.open_in_encyclopedia"))
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.cyan)
                .padding(.horizontal, 8 * zoomScale)
                .padding(.vertical, 3 * zoomScale)
                .background(.cyan.opacity(0.1))
                .cornerRadius(4 * zoomScale)
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1 * zoomScale)
                        .allowsHitTesting(false)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "doc.text.fill", title: String(localized: "error.description"), zoomScale: zoomScale)
            
            Text(entry.description)
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3 * zoomScale)
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Cause Section
    private var causeSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "questionmark.circle.fill", title: String(localized: "error.root_cause"), zoomScale: zoomScale)
            
            let causes = entry.cause.components(separatedBy: "\n").filter { !$0.isEmpty }
            VStack(alignment: .leading, spacing: 4 * zoomScale) {
                ForEach(Array(causes.enumerated()), id: \.offset) { index, cause in
                    HStack(alignment: .top, spacing: 6 * zoomScale) {
                        Text("\(index + 1).")
                            .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                        
                        Text(cause.trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Solutions Section
    private var solutionsSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "checkmark.seal.fill", title: String(format: String(localized: "error.solutions_count"), entry.solutions.count), zoomScale: zoomScale)
            
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                ForEach(Array(entry.solutions.enumerated()), id: \.offset) { index, solution in
                    HStack(alignment: .top, spacing: 6 * zoomScale) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10 * zoomScale))
                            .foregroundStyle(.green)
                        
                        Text(solution)
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(8 * zoomScale)
                    .background(Color(white: 0.05))
                    .cornerRadius(6 * zoomScale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                            .stroke(.green.opacity(0.15), lineWidth: 1 * zoomScale)
                    
                        .allowsHitTesting(false))
                }
            }
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Code Examples Section
    private var codeExamplesSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "curlybraces", title: String(localized: "error.code_examples"), zoomScale: zoomScale)
            
            ForEach(entry.codeExamples) { example in
                VStack(alignment: .leading, spacing: 6 * zoomScale) {
                    HStack {
                        Text(example.title)
                            .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(example.goodCode, forType: .string)
                            copiedCode = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedCode = false
                            }
                        }) {
                            HStack(spacing: 3 * zoomScale) {
                                Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 8 * zoomScale))
                                Text(copiedCode ? String(localized: "error.copied") : String(localized: "error.copy_fix"))
                                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                            }
                            .foregroundStyle(copiedCode ? .green : .white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Bad code
                    VStack(alignment: .leading, spacing: 4 * zoomScale) {
                        HStack {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.red)
                            Text(String(localized: "error.problematic_code"))
                                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red)
                        }
                        
                        Text(example.badCode)
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(8 * zoomScale)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.05))
                            .cornerRadius(4 * zoomScale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4 * zoomScale)
                                    .stroke(.red.opacity(0.2), lineWidth: 1 * zoomScale)
                            
                                .allowsHitTesting(false))
                    }
                    
                    // Good code
                    VStack(alignment: .leading, spacing: 4 * zoomScale) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.green)
                            Text(String(localized: "error.fixed_code"))
                                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                        
                        Text(example.goodCode)
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.9))
                            .padding(8 * zoomScale)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.green.opacity(0.05))
                            .cornerRadius(4 * zoomScale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4 * zoomScale)
                                    .stroke(.green.opacity(0.2), lineWidth: 1 * zoomScale)
                            
                                .allowsHitTesting(false))
                    }
                    
                    // Explanation
                    Text(example.explanation)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineSpacing(2 * zoomScale)
                }
                .padding(10 * zoomScale)
                .background(Color(white: 0.04))
                .cornerRadius(8 * zoomScale)
                .overlay(
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                
                    .allowsHitTesting(false))
            }
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Related Errors Section
    private var relatedErrorsSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "link", title: String(localized: "error.related_errors"), zoomScale: zoomScale)
            
            let related = ErrorKnowledgeBase.shared.findRelated(to: entry)
            
            if related.isEmpty {
                Text(String(localized: "error.no_related"))
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                VStack(alignment: .leading, spacing: 4 * zoomScale) {
                    ForEach(related) { relatedEntry in
                        HStack(spacing: 6 * zoomScale) {
                            Circle()
                                .fill(Color(hex: relatedEntry.severity.colorHex))
                                .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                            Text(relatedEntry.title)
                                .font(.system(size: 10 * zoomScale, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                        }
                        .padding(6 * zoomScale)
                        .background(Color(white: 0.05))
                        .cornerRadius(4 * zoomScale)
                    }
                }
            }
            
            if !entry.relatedErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4 * zoomScale) {
                    Text(String(localized: "error.also_known_as"))
                        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    ForEach(entry.relatedErrors, id: \.self) { name in
                        Text("• \(name)")
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
    
    // MARK: - Meta Section
    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            SectionHeader(icon: "info.circle.fill", title: String(localized: "error.additional_info"), zoomScale: zoomScale)
            
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                if let url = entry.appleDocURL {
                    HStack(spacing: 6 * zoomScale) {
                        Image(systemName: "globe")
                            .font(.system(size: 9 * zoomScale))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(String(localized: "error.apple_documentation"))
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            if let url = URL(string: url) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("button.open")
                                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if !entry.commonInVersions.isEmpty {
                    HStack(spacing: 6 * zoomScale) {
                        Image(systemName: "number")
                            .font(.system(size: 9 * zoomScale))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("error.common_in")
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(entry.commonInVersions.joined(separator: ", "))
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                
                HStack(spacing: 6 * zoomScale) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("error.tags")
                        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(entry.tags.joined(separator: ", "))
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(12 * zoomScale)
        .background(Color(white: 0.02))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let icon: String
    let title: String
    let zoomScale: CGFloat
    
    var body: some View {
        HStack(spacing: 6 * zoomScale) {
            Image(systemName: icon)
                .font(.system(size: 11 * zoomScale))
                .foregroundStyle(.white.opacity(0.6))
            Text(title)
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }
}
