import Testing
@testable import ClassGod

@Suite("Interaction feedback state")
struct InteractionFeedbackTests {
    @Test("Feedback is scoped to the latest item")
    func scopesFeedbackToLatestItem() {
        var state = TransientFeedbackState<String>()
        let first = state.present("first")
        let second = state.present("second")

        #expect(state.value == "second")
        let dismissedFirst = state.dismiss(ifCurrent: first)
        #expect(!dismissedFirst)
        #expect(state.value == "second")
        let dismissedSecond = state.dismiss(ifCurrent: second)
        #expect(dismissedSecond)
        #expect(state.value == nil)
    }

    @Test("Activity permission prompt requires an active empty monitor")
    func validatesActivityPermissionPrompt() {
        #expect(ActivityPermissionPromptPolicy.shouldShow(isMonitoring: true, processCount: 0))
        #expect(!ActivityPermissionPromptPolicy.shouldShow(isMonitoring: false, processCount: 0))
        #expect(!ActivityPermissionPromptPolicy.shouldShow(isMonitoring: true, processCount: 1))
    }
}
