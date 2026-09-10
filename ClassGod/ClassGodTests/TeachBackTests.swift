import Testing
@testable import ClassGod

@Suite("Teach Back")
struct TeachBackTests {
    @Test("Required steps reject whitespace and preserve text when navigating")
    func navigatesDraft() {
        var session = TeachBackSession()
        #expect(session.next() == false)
        session.update(.topic, text: "  \n ")
        #expect(session.next() == false)
        session.update(.topic, text: "Gravity")
        #expect(session.next() == true)
        #expect(session.step == .explanation)
        session.update(.explanation, text: "Mass attracts mass.")
        session.previous()
        #expect(session.text(for: .explanation) == "Mass attracts mass.")
        #expect(session.step == .topic)
    }

    @Test("Character limits never split a composed Unicode character")
    func boundsInput() {
        var session = TeachBackSession()
        let family = "👨‍👩‍👧‍👦"
        session.update(.topic, text: String(repeating: family, count: 121))
        #expect(session.text(for: .topic) == String(repeating: family, count: 120))
        session.update(.explanation, text: String(repeating: "学", count: 2_100))
        #expect(session.text(for: .explanation).count == 2_000)
    }

    @Test("Review requires an explanation and example; gaps remain optional")
    func completesWorksheet() {
        var session = readySession()
        #expect(session.isReviewing)
        #expect(session.next() == false)
        #expect(session.checked.isEmpty)
        session.toggle(.ownWords)
        session.toggle(.ownWords)
        #expect(session.checked.isEmpty)
        session.toggle(.exampleFits)
        #expect(session.checked.count == 1)
        session.previous()
        #expect(!session.isReviewing)
        #expect(session.step == .gap)
    }

    @Test("Editing clears the self-check and reset removes every answer")
    func invalidatesReview() {
        var session = readySession()
        session.toggle(.ownWords)
        session.update(.explanation, text: "A clearer explanation")
        #expect(session.checked.isEmpty)
        #expect(!session.isReviewing)
        session = TeachBackSession()
        #expect(TeachBackStep.allCases.allSatisfy { session.text(for: $0).isEmpty })
    }

    @Test("Summary keeps plain text, skips empty optional sections, and requires a complete draft")
    func exportsSummary() {
        var session = TeachBackSession()
        let headings = ["Topic", "Explanation", "Example", "Gap"]
        #expect(session.summary(headings: headings) == nil)
        session = readySession()
        #expect(session.summary(headings: headings) == "Topic\nGravity\n\nExplanation\nMass attracts mass.\n\nExample\nAn apple falls.")
        #expect(session.summary(headings: []) == nil)
    }

    private func readySession() -> TeachBackSession {
        var session = TeachBackSession()
        session.update(.topic, text: "Gravity")
        _ = session.next()
        session.update(.explanation, text: "Mass attracts mass.")
        _ = session.next()
        session.update(.example, text: "An apple falls.")
        _ = session.next()
        _ = session.next()
        return session
    }
}
