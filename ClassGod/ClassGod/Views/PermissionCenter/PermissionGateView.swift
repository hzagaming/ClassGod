import AppKit
import SwiftUI

struct PermissionGateView: View {
    @StateObject private var service = PermissionCenterService.shared
    @ObservedObject private var prefs = PreferencesManager.shared

    let onQuit: () -> Void

    private var progress: PermissionGateProgress { service.gateProgress }
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressSection
            permissionList
            footer
        }
        .background(Color.black)
        .tint(accent)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 14 * zoomScale)
                .stroke(accent.opacity(0.28), lineWidth: 1 * zoomScale)
        )
        .onAppear { service.refreshAll() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            service.refreshAll()
        }
    }

    private var header: some View {
        HStack(spacing: 12 * zoomScale) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 42 * zoomScale, height: 42 * zoomScale)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 19 * zoomScale, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3 * zoomScale) {
                Text("permission.gate.title")
                    .font(.system(size: 18 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("permission.gate.subtitle")
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
            }
            Spacer()
            Text("permission.gate.brand")
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.75))
        }
        .padding(.horizontal, 18 * zoomScale)
        .padding(.vertical, 14 * zoomScale)
        .background(Color(white: 0.025))
    }

    private var progressSection: some View {
        VStack(spacing: 8 * zoomScale) {
            HStack {
                Text(String(format: String(localized: "permission.gate.progress"), progress.completed, progress.total))
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(progress.isUnlocked ? .green : accent)
                Spacer()
                Text("permission.gate.requirement")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(progress.isUnlocked ? Color.green : accent)
                        .frame(width: geometry.size.width * CGFloat(progress.completed) / CGFloat(max(1, progress.total)))
                }
            }
            .frame(height: 8 * zoomScale)
        }
        .padding(.horizontal, 18 * zoomScale)
        .padding(.vertical, 12 * zoomScale)
        .background(Color(white: 0.04))
    }

    private var permissionList: some View {
        ScrollView {
            LazyVStack(spacing: 7 * zoomScale) {
                ForEach(PermissionType.allCases) { type in
                    permissionRow(type)
                }
            }
            .padding(14 * zoomScale)
        }
        .background(Color(white: 0.015))
    }

    private func permissionRow(_ type: PermissionType) -> some View {
        let state = PermissionCatalogPolicy.state(for: type, statuses: service.statuses)
        let confirmed = service.isManuallyConfirmed(type)
        let complete = type.requiresManualReview ? confirmed : state.isGranted
        let color: Color = complete ? .green : (state == .restricted ? .red : .orange)

        return HStack(spacing: 11 * zoomScale) {
            Image(systemName: type.iconName)
                .font(.system(size: 14 * zoomScale, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3 * zoomScale) {
                HStack(spacing: 7 * zoomScale) {
                    Text(type.title)
                        .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(type.requiresManualReview
                         ? String(localized: "permission.gate.manual_badge")
                         : String(localized: "permission.gate.automatic_badge"))
                        .font(.system(size: 7 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(type.requiresManualReview ? accent : .white.opacity(0.5))
                        .padding(.horizontal, 5 * zoomScale)
                        .padding(.vertical, 2 * zoomScale)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                }
                Text(type.description)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(2)
            }

            Spacer(minLength: 10 * zoomScale)

            HStack(spacing: 7 * zoomScale) {
                statusLabel(complete: complete, state: state, color: color)
                actionControls(type: type, state: state, confirmed: confirmed)
            }
        }
        .padding(.horizontal, 11 * zoomScale)
        .padding(.vertical, 9 * zoomScale)
        .background(Color(white: 0.045))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(color.opacity(complete ? 0.2 : 0.1), lineWidth: 1 * zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }

    private func statusLabel(
        complete: Bool,
        state: PermissionAuthorizationState,
        color: Color
    ) -> some View {
        HStack(spacing: 4 * zoomScale) {
            Image(systemName: complete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(complete ? String(localized: "permission.gate.complete") : state.displayName)
        }
        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
        .foregroundStyle(color)
        .frame(minWidth: 86 * zoomScale, alignment: .trailing)
    }

    @ViewBuilder
    private func actionControls(
        type: PermissionType,
        state: PermissionAuthorizationState,
        confirmed: Bool
    ) -> some View {
        if type.requiresManualReview {
            actionButton(title: "permission.open_settings", emphasized: !confirmed) {
                service.requestPermission(type)
            }
            actionButton(
                title: confirmed ? "permission.gate.undo_confirmation" : "permission.gate.confirm_review",
                emphasized: confirmed
            ) {
                service.setManualConfirmation(type, confirmed: !confirmed)
            }
            .disabled(!confirmed && !service.canConfirmManualReview(type))
            .opacity(!confirmed && !service.canConfirmManualReview(type) ? 0.42 : 1)
        } else {
            actionButton(title: actionTitle(for: type, state: state), emphasized: !state.isGranted) {
                service.requestPermission(type)
            }
            .disabled(service.isChecking || service.isRequesting(type))
        }
    }

    private func actionButton(
        title: LocalizedStringKey,
        emphasized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(emphasized ? .black : .white.opacity(0.72))
                .padding(.horizontal, 9 * zoomScale)
                .frame(height: 25 * zoomScale)
                .background(emphasized ? accent : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
        }
        .buttonStyle(.plain)
    }

    private func actionTitle(
        for type: PermissionType,
        state: PermissionAuthorizationState
    ) -> LocalizedStringKey {
        if service.isRequesting(type) { return "permission.checking" }
        switch PermissionRequestPolicy.action(for: type, state: state) {
        case .refresh: return "permission.recheck"
        case .prompt: return "permission.allow"
        case .openSettings: return "permission.open_settings"
        }
    }

    private var footer: some View {
        HStack(spacing: 10 * zoomScale) {
            Image(systemName: "info.circle")
                .foregroundStyle(accent.opacity(0.7))
            Text("permission.gate.system_note")
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(2)
            Spacer()
            Button {
                service.refreshAll()
            } label: {
                Label("permission.refresh_status", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(service.isChecking)

            Button(role: .destructive, action: onQuit) {
                Label("button.quit", systemImage: "power")
            }
            .buttonStyle(.bordered)
        }
        .font(.system(size: 9 * zoomScale, weight: .semibold, design: .monospaced))
        .padding(.horizontal, 18 * zoomScale)
        .padding(.vertical, 11 * zoomScale)
        .background(Color(white: 0.03))
    }
}
