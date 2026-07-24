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
        PermissionType.allCases.filter { !$0.requiresManualReview }.count
    }

    private var manualCount: Int {
        PermissionType.allCases.filter(\.requiresManualReview).count
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
        .onReceive(NotificationCenter.default.publisher(for: .permissionCenterWindowDidShow)) { _ in
            service.refreshAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
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
                Text("permission.center.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("permission.center.subtitle")
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
                    Text("permission.first_time_setup")
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
                Text("permission.status")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(String(format: String(localized: "permission.progress_format"), grantedCount, totalCount, manualCount))
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
                categoryButton(nil, label: String(localized: "permission.category.all"), icon: "square.grid.2x2")
                ForEach(PermissionCategory.allCases) { cat in
                    categoryButton(cat, label: cat.displayName, icon: cat.iconName)
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
            HapticManager.shared.generic()
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
                Text(group.category.displayName)
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
        let manual = item.requiresManualReview
        let statusColor: Color = granted ? .green : (manual ? .cyan : .orange)
        
        return HStack(spacing: 10 * zoomScale) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                Image(systemName: item.type.iconName)
                    .font(.system(size: 14 * zoomScale))
                    .foregroundStyle(statusColor)
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
                    Text(String(localized: "permission.used_by"))
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
                        .fill(statusColor)
                        .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                    Text(statusTitle(granted: granted, manual: manual))
                        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                }
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    if granted {
                        service.refreshAll()
                    } else {
                        service.requestPermission(item.type)
                    }
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
                .stroke(statusColor.opacity(granted ? 0.2 : 0.1), lineWidth: 1 * zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }
    
    private func buttonTitle(for item: PermissionItemInfo, granted: Bool) -> String {
        if granted {
            return item.canPrompt ? String(localized: "permission.recheck") : String(localized: "permission.open_settings")
        }
        return item.canPrompt ? String(localized: "permission.allow") : String(localized: "permission.open_settings")
    }

    private func statusTitle(granted: Bool, manual: Bool) -> String {
        if granted { return String(localized: "permission.granted") }
        if manual { return String(localized: "permission.manual_review") }
        return String(localized: "permission.required")
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
                    Text(String(localized: "permission.refresh_status"))
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
            
            Text(service.isChecking ? String(localized: "permission.checking") : String(format: String(localized: "permission.last_checked"), formatTime(service.statuses.values.first?.lastChecked)))
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
        guard let date else { return String(localized: "permission.never") }
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
    @State private var setupPermissions: [PermissionItemInfo] = []
    var onComplete: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var pendingPermissions: [PermissionItemInfo] {
        setupPermissions
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.03).ignoresSafeArea()
            
            VStack(spacing: 16 * zoomScale) {
                HStack {
                    Spacer()
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                        onComplete()
                    }) {
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
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            step -= 1
                        }) {
                            Text(String(localized: "button.back"))
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
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            service.requestPermission(item.type)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                service.refreshAll()
                                step += 1
                            }
                        }) {
                            Text(item.canPrompt ? String(localized: "permission.allow_and_continue") : String(localized: "permission.open_settings_and_continue"))
                                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                                .background(Color.cyan.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            step += 1
                        }) {
                            Text(String(localized: "button.skip"))
                                .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 14 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            onComplete()
                        }) {
                            Text(String(localized: "button.done"))
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
        .onAppear {
            setupPermissions = service.allPermissions.filter {
                $0.type.isRecommendedForSetup && service.statuses[$0.type]?.isGranted != true
            }
            step = 0
        }
    }
    
    private func onboardingStep(_ item: PermissionItemInfo, index: Int, total: Int) -> some View {
        VStack(spacing: 14 * zoomScale) {
            Text(String(format: String(localized: "permission.step_format"), index + 1, total))
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
                Text(String(localized: "permission.required_for"))
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
                Text(String(localized: "permission.manual_settings"))
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
            
            Text(String(localized: "permission.all_set"))
                .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            Text(String(localized: "permission.all_set_message"))
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360 * zoomScale)
        }
    }
}
