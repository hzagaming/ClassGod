nonisolated struct QuietDevice: Equatable {
    let uid: String
    let name: String
}

nonisolated enum QuietDeskNotice { case ready, muted, restored, alreadyMuted, unavailable, muteFailed, restoreFailed }
