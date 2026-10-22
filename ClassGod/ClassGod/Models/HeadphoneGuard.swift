import Foundation

nonisolated enum HeadphoneGuardNotice { case ready, armed, disarmed, unavailable, restored, restoreFailed }

nonisolated enum HeadphoneGuardOutcome: Equatable { case silenced, alreadySilent, unsupported, failed }

nonisolated struct HeadphoneGuardTrip: Equatable {
    let device: QuietDevice
    let date: Date
    let outcome: HeadphoneGuardOutcome
}
