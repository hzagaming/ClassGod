//
//  PermissionCenterView.swift
//  ClassGod
//
//  Hacker-style permission control center for managing all macOS permissions.
//

import SwiftUI

struct PermissionCenterView: View {
    @StateObject private var service = PermissionCenterService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var selectedCategory: PermissionCategory? = nil
    @State private var showingOnboarding = false
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var groupedPermissions: [(category: PermissionCategory, items: [PermissionItemInfo])] {
        let grouped = Dictionary(grouping: service.allPermissions) { $0.category }
        return PermissionCategory.allCases.compactMap { cat in
            grouped[cat].map { (category: cat, items: $0) }
        }
    }
    
    private var grantedCount: Int {
        service.statuses.values.filter(\.isGranted).count
    }
    
    private var totalCount: Int {
        PermissionType.allCases.count
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.02).ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                progressBar
                categoryFilterBar
                permissionList
                bottomBar
            }
        }
        .onAppear {
            service.refreshAll()
        }
        .sheet(isPresented: $showingOnboarding) {
            PermissionOnboardingView(service: service) {
                showingOnboarding = false
            }
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack(spacing: 12 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 14 * zoomScale))
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Permission Center")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Control what ClassGod can access on your Mac")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                showingOnboarding = true
            }) {
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 9 * zoomScale))
                    Text("First-Time Setup")
                        .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10 * zoomScale)
                .padding(.vertical, 5 * zoomScale)
                .background(Color.cyan.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.04))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .offset(y: 0.5)
        )
    }
    
    // MARK: - Progress
    
    private var progressBar: some View {
        VStack(spacing: 4 * zoomScale) {
            HStack {
                Text("Permission Status")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(grantedCount)/\(totalCount) granted")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(progressColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3 * zoomScale)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3 * zoomScale)
                        .fill(progressColor)
                        .frame(width: max(2, geo.size.width * CGFloat(grantedCount) / CGFloat(max(1, totalCount))))
                }
            }
            .frame(height: 8 * zoomScale)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.03))
    }
    
    private var progressColor: Color {
        let ratio = Double(grantedCount) / Double(max(1, totalCount))
        if ratio >= 1.0 { return .green }
        if ratio >= 0.6 { return .yellow }
        return .orange
    }
    
    // MARK: - Category Filter
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6 * zoomScale) {
                categoryButton(nil, label: "All", icon: "square.grid.2x2")
                ForEach(PermissionCategory.allCases) { cat in
                    categoryButton(cat, label: cat.rawValue, icon: cat.iconName)
                }
            }
            .padding(.horizontal, 12 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
        }
        .background(Color(white: 0.04))
    }
    
    private func categoryButton(_ category: PermissionCategory?, label: String, icon: String) -> some View {
        let selected = selectedCategory == category
        return Button(action: {
            SoundEffectManager.shared.playButtonClick()
            selectedCategory = category
        }) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: icon)
                    .font(.system(size: 9 * zoomScale))
                Text(label)
                    .font(.system(size: 9 * zoomScale, weight: selected ? .bold : .medium, design: .monospaced))
            }
            .foregroundStyle(selected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 10 * zoomScale)
            .padding(.vertical, 4 * zoomScale)
            .background(selected ? Color.cyan.opacity(0.85) : Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Permission List
    
    private var permissionList: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 12 * zoomScale) {
                ForEach(visibleGroups, id: \.category.id) { group in
                    categorySection(group)
                }
            }
            .padding(12 * zoomScale)
        }
        .background(Color(white: 0.02))
    }
    
    private var visibleGroups: [(category: PermissionCategory, items: [PermissionItemInfo])] {
        if let selected = selectedCategory {
            return groupedPermissions.filter { $0.category == selected }
        }
        return groupedPermissions
    }
    
    private func categorySection(_ group: (category: PermissionCategory, items: [PermissionItemInfo])) -> some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            HStack(spacing: 6 * zoomScale) {
                Image(systemName: group.category.iconName)
                    .font(.system(size: 10 * zoomScale))
                    .foregroundStyle(.cyan)
                Text(group.category.rawValue)
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            
            VStack(spacing: 4 * zoomScale) {
                ForEach(group.items) { item in
                    permissionCard(item)
                }
            }
        }
    }
    
    private func permissionCard(_ item: PermissionItemInfo) -> some View {
        let status = service.statuses[item.type]
        let granted = status?.isGranted ?? false
        
        return HStack(spacing: 10 * zoomScale) {
            // Icon
            ZStack {
                Circle()
                    .fill(granted ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                Image(systemName: item.type.iconName)
                    .font(.system(size: 14 * zoomScale))
                    .foregroundStyle(granted ? .green : .orange)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text(item.title)
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(item.description)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
                
                HStack(spacing: 4 * zoomScale) {
                    Text("Used by:")
                        .font(.system(size: 7 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Text(item.features.joined(separator: ", "))
                        .font(.system(size: 7 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.7))
                }
            }
            
            Spacer(minLength: 8 * zoomScale)
            
            // Status + Action
            VStack(alignment: .trailing, spacing: 4 * zoomScale) {
                HStack(spacing: 3 * zoomScale) {
                    Circle()
                        .fill(granted ? Color.green : Color.orange)
                        .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                    Text(granted ? "Granted" : "Required")
                        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(granted ? .green : .orange)
                }
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    service.requestPermission(item.type)
                }) {
                    Text(buttonTitle(for: item, granted: granted))
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10 * zoomScale)
                        .padding(.vertical, 4 * zoomScale)
                        .background(granted ? Color.white.opacity(0.7) : Color.cyan.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
                }
                .buttonStyle(.plain)
                .disabled(service.isChecking)
            }
        }
        .padding(10 * zoomScale)
        .background(Color(white: 0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(granted ? Color.green.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }
    
    private func buttonTitle(for item: PermissionItemInfo, granted: Bool) -> String {
        if granted {
            return item.canPrompt ? "Re-check" : "Open Settings"
        }
        return item.canPrompt ? "Allow" : "Open Settings"
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 12 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                service.refreshAll()
            }) {
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9 * zoomScale))
                    Text("Refresh Status")
                        .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 10 * zoomScale)
                .padding(.vertical, 5 * zoomScale)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
            .disabled(service.isChecking)
            
            Spacer()
            
            Text(service.isChecking ? "Checking permissions..." : "Last checked: \(formatTime(service.statuses.values.first?.lastChecked))")
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.04))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .offset(y: -0.5)
        )
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date else { return "never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Onboarding Sheet

struct PermissionOnboardingView: View {
    @ObservedObject var service: PermissionCenterService
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var step = 0
    var onComplete: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var pendingPermissions: [PermissionItemInfo] {
        service.allPermissions.filter { service.statuses[$0.type]?.isGranted != true }
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.03).ignoresSafeArea()
            
            VStack(spacing: 16 * zoomScale) {
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10 * zoomScale, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                if pendingPermissions.isEmpty {
                    onboardingComplete
                } else if step < pendingPermissions.count {
                    onboardingStep(pendingPermissions[step], index: step, total: pendingPermissions.count)
                } else {
                    onboardingComplete
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 10 * zoomScale) {
                    if step > 0 && step < pendingPermissions.count {
                        Button(action: { step -= 1 }) {
                            Text("Back")
                                .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 14 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                                .background(Color(white: 0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    if step < pendingPermissions.count {
                        let item = pendingPermissions[step]
                        Button(action: {
                            service.requestPermission(item.type)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                service.refreshAll()
                                step += 1
                            }
                        }) {
                            Text(item.canPrompt ? "Allow & Continue" : "Open Settings & Continue")
                                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                                .background(Color.cyan.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { step += 1 }) {
                            Text("Skip")
                                .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 14 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: onComplete) {
                            Text("Done")
                                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 20 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                                .background(Color.green.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20 * zoomScale)
        }
        .frame(minWidth: 420 * zoomScale, minHeight: 320 * zoomScale)
    }
    
    private func onboardingStep(_ item: PermissionItemInfo, index: Int, total: Int) -> some View {
        VStack(spacing: 14 * zoomScale) {
            Text("Step \(index + 1) of \(total)")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 64 * zoomScale, height: 64 * zoomScale)
                Image(systemName: item.type.iconName)
                    .font(.system(size: 28 * zoomScale))
                    .foregroundStyle(.orange)
            }
            
            Text(item.title)
                .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            Text(item.description)
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360 * zoomScale)
            
            VStack(alignment: .leading, spacing: 4 * zoomScale) {
                Text("Required for:")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                HStack(spacing: 6 * zoomScale) {
                    ForEach(item.features, id: \.self) { feature in
                        Text(feature)
                            .font(.system(size: 8 * zoomScale, weight: .medium, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 6 * zoomScale)
                            .padding(.vertical, 2 * zoomScale)
                            .background(Color.cyan.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))
                    }
                }
            }
            
            if !item.canPrompt {
                Text("macOS will open System Settings so you can enable this permission manually.")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320 * zoomScale)
                    .padding(.top, 4 * zoomScale)
            }
        }
    }
    
    private var onboardingComplete: some View {
        VStack(spacing: 14 * zoomScale) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 64 * zoomScale, height: 64 * zoomScale)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28 * zoomScale))
                    .foregroundStyle(.green)
            }
            
            Text("All Set")
                .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            Text("All requested permissions have been reviewed. You can change these anytime in Permission Center.")
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360 * zoomScale)
        }
    }
}
