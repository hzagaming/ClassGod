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
    @State private var selectedStatusFilter = PermissionStatusFilter.all
    @State private var selectedRequirementFilter = PermissionRequirementFilter.all
    @State private var selectedSortOrder = PermissionSortOrder.attention
    @State private var searchText = ""
    @State private var showingOnboarding = false
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var visiblePermissions: [PermissionItemInfo] {
        PermissionCatalogPolicy.items(
            from: service.allPermissions,
            statuses: service.statuses,
            category: selectedCategory,
            statusFilter: selectedStatusFilter,
            requirementFilter: selectedRequirementFilter,
            searchText: searchText,
            sortOrder: selectedSortOrder
        )
    }

    private var visibleGroups: [(category: PermissionCategory, items: [PermissionItemInfo])] {
        let grouped = Dictionary(grouping: visiblePermissions) { $0.category }
        return PermissionCategory.allCases.compactMap { cat in
            grouped[cat].map { (category: cat, items: $0) }
        }
    }

    private var summary: PermissionSummary {
        PermissionCatalogPolicy.summary(for: PermissionType.allCases, statuses: service.statuses)
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.02).ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                progressBar
                categoryFilterBar
                statusFilterBar
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
            .accessibilityLabel(Text("button.close"))
            
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
                Text(String(format: String(localized: "permission.progress_format"), summary.granted, summary.queryableTotal, summary.manualReview))
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(progressColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3 * zoomScale)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3 * zoomScale)
                        .fill(progressColor)
                        .frame(width: max(2, geo.size.width * CGFloat(summary.granted) / CGFloat(max(1, summary.queryableTotal))))
                }
            }
            .frame(height: 8 * zoomScale)

            HStack(spacing: 12 * zoomScale) {
                statusMetric(
                    value: summary.granted,
                    label: "permission.filter.granted",
                    color: .green
                )
                statusMetric(
                    value: summary.actionNeeded,
                    label: "permission.filter.action_needed",
                    color: .orange
                )
                statusMetric(
                    value: summary.manualReview,
                    label: "permission.filter.manual",
                    color: .cyan
                )
                statusMetric(
                    value: summary.requiredPending,
                    label: "permission.required_pending",
                    color: .red
                )
                Spacer()
            }
            .padding(.top, 3 * zoomScale)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.03))
    }
    
    private var progressColor: Color {
        let ratio = Double(summary.granted) / Double(max(1, summary.queryableTotal))
        if ratio >= 1.0 { return .green }
        if ratio >= 0.6 { return .yellow }
        return .orange
    }

    private func statusMetric(value: Int, label: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 4 * zoomScale) {
            Circle()
                .fill(color)
                .frame(width: 5 * zoomScale, height: 5 * zoomScale)
            Text("\(value)")
                .foregroundStyle(.white.opacity(0.85))
            Text(label)
                .foregroundStyle(.white.opacity(0.45))
        }
        .font(.system(size: 8 * zoomScale, weight: .medium, design: .monospaced))
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

    private var statusFilterBar: some View {
        VStack(spacing: 6 * zoomScale) {
            HStack(spacing: 6 * zoomScale) {
                searchField
                requirementMenu
                sortMenu
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6 * zoomScale) {
                    ForEach(PermissionStatusFilter.allCases) { filter in
                        Button {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            selectedStatusFilter = filter
                        } label: {
                            HStack(spacing: 5 * zoomScale) {
                                Text(filter.title)
                                Text("\(count(for: filter))")
                                    .foregroundStyle(selectedStatusFilter == filter ? .black.opacity(0.6) : .white.opacity(0.35))
                            }
                            .font(.system(size: 8 * zoomScale, weight: selectedStatusFilter == filter ? .bold : .medium, design: .monospaced))
                            .foregroundStyle(selectedStatusFilter == filter ? .black : .white.opacity(0.6))
                            .padding(.horizontal, 8 * zoomScale)
                            .frame(height: 24 * zoomScale)
                            .background(selectedStatusFilter == filter ? Color.cyan.opacity(0.85) : Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 7 * zoomScale)
        .background(Color(white: 0.03))
    }

    private var searchField: some View {
        HStack(spacing: 5 * zoomScale) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 9 * zoomScale))
                .foregroundStyle(.white.opacity(0.35))
            TextField(String(localized: "permission.search_placeholder"), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
            if !searchText.isEmpty {
                Button {
                    SoundEffectManager.shared.playButtonClick()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.clear"))
            }
        }
        .padding(.horizontal, 8 * zoomScale)
        .frame(maxWidth: .infinity, minHeight: 26 * zoomScale)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }

    private var requirementMenu: some View {
        Menu {
            ForEach(PermissionRequirementFilter.allCases) { filter in
                Button(filter.displayName) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    selectedRequirementFilter = filter
                }
            }
        } label: {
            compactMenuLabel(icon: "exclamationmark.shield", title: selectedRequirementFilter.displayName)
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel(Text("permission.filter.requirement"))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(PermissionSortOrder.allCases) { order in
                Button(order.displayName) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    selectedSortOrder = order
                }
            }
        } label: {
            compactMenuLabel(icon: "arrow.up.arrow.down", title: selectedSortOrder.displayName)
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel(Text("permission.sort.label"))
    }

    private func compactMenuLabel(icon: String, title: String) -> some View {
        HStack(spacing: 4 * zoomScale) {
            Image(systemName: icon)
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 6 * zoomScale, weight: .bold))
        }
        .font(.system(size: 8 * zoomScale, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 8 * zoomScale)
        .frame(height: 26 * zoomScale)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }

    private func count(for filter: PermissionStatusFilter) -> Int {
        switch filter {
        case .all: PermissionType.allCases.count
        case .actionNeeded: summary.actionNeeded
        case .granted: summary.granted
        case .manualReview: summary.manualReview
        }
    }
    
    // MARK: - Permission List
    
    private var permissionList: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 12 * zoomScale) {
                if visibleGroups.isEmpty {
                    VStack(spacing: 8 * zoomScale) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 24 * zoomScale))
                            .foregroundStyle(.white.opacity(0.25))
                        Text("permission.no_results")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64 * zoomScale)
                } else {
                    ForEach(visibleGroups, id: \.category.id) { group in
                        categorySection(group)
                    }
                }
            }
            .padding(12 * zoomScale)
        }
        .background(Color(white: 0.02))
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
        let state = PermissionCatalogPolicy.state(for: item.type, statuses: service.statuses)
        let statusColor = color(for: state)
        
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
                HStack(spacing: 4 * zoomScale) {
                    metadataChip(item.type.requirement.displayName, color: requirementColor(item.type.requirement))
                    metadataChip(item.requestMethod.displayName, color: .cyan)
                    metadataChip(item.statusDetection.displayName, color: item.requiresManualReview ? .orange : .green)
                }
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
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8 * zoomScale)
            
            // Status + Action
            VStack(alignment: .trailing, spacing: 4 * zoomScale) {
                HStack(spacing: 3 * zoomScale) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                    Text(statusTitle(state))
                        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                }

                if let lastChecked = status?.lastChecked {
                    Text(formatTime(lastChecked))
                        .font(.system(size: 7 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    service.requestPermission(item.type)
                }) {
                    Text(service.isRequesting(item.type) ? String(localized: "permission.checking") : buttonTitle(for: item, state: state))
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10 * zoomScale)
                        .padding(.vertical, 4 * zoomScale)
                        .background(state.isGranted ? Color.white.opacity(0.7) : Color.cyan.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
                }
                .buttonStyle(.plain)
                .disabled(service.isChecking || service.isRequesting(item.type))
            }
        }
        .padding(10 * zoomScale)
        .background(Color(white: 0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(statusColor.opacity(state.isGranted ? 0.2 : 0.1), lineWidth: 1 * zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }

    private func metadataChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 6.5 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 5 * zoomScale)
            .padding(.vertical, 1.5 * zoomScale)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3 * zoomScale))
    }
    
    private func buttonTitle(for item: PermissionItemInfo, state: PermissionAuthorizationState) -> String {
        switch PermissionRequestPolicy.action(for: item.type, state: state) {
        case .refresh: return String(localized: "permission.recheck")
        case .prompt: return String(localized: "permission.allow")
        case .openSettings: return String(localized: "permission.open_settings")
        }
    }

    private func statusTitle(_ state: PermissionAuthorizationState) -> String {
        state.displayName
    }

    private func color(for state: PermissionAuthorizationState) -> Color {
        switch state {
        case .granted: .green
        case .denied: .orange
        case .notDetermined: .yellow
        case .restricted: .red
        case .manualReview: .cyan
        }
    }

    private func requirementColor(_ requirement: PermissionRequirement) -> Color {
        switch requirement {
        case .required: .orange
        case .recommended: .cyan
        case .optional: .white.opacity(0.35)
        }
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
                    .accessibilityLabel(Text("button.close"))
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
                        }) {
                            Text(service.isRequesting(item.type) ? String(localized: "permission.checking") : onboardingActionTitle(item))
                                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16 * zoomScale)
                                .padding(.vertical, 6 * zoomScale)
                                .background(Color.cyan.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        }
                        .buttonStyle(.plain)
                        .disabled(service.isChecking || service.isRequesting(item.type))
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            step += 1
                        }) {
                            Text(String(localized: "button.next"))
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
            let itemsByType = Dictionary(uniqueKeysWithValues: service.allPermissions.map { ($0.type, $0) })
            setupPermissions = PermissionReviewPlan.all.compactMap { itemsByType[$0] }
            step = 0
        }
    }

    private func onboardingActionTitle(_ item: PermissionItemInfo) -> String {
        let state = service.statuses[item.type]?.state ?? (item.requiresManualReview ? .manualReview : .notDetermined)
        switch PermissionRequestPolicy.action(for: item.type, state: state) {
        case .refresh: return String(localized: "permission.recheck")
        case .prompt: return String(localized: "permission.allow")
        case .openSettings: return String(localized: "permission.open_settings")
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
