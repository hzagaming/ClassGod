import Testing
@testable import ClassGod

@Suite("Reading Lane")
struct ReadingLaneTests {
    @Test("Blank lines define passages across Windows and Mac line endings")
    func separatesParagraphs() {
        #expect(ReadingLanePolicy.passages(" First\r\nline\r\n \r\n第二段\r\rThird ") == ["First\nline", "第二段", "Third"])
        #expect(ReadingLanePolicy.passages(" \n\t\n").isEmpty)
    }

    @Test("Long passages are split without breaking Unicode characters or dropping content")
    func boundsPassages() {
        let text = String(repeating: "👨‍👩‍👧‍👦学", count: 1_000)
        let passages = ReadingLanePolicy.passages(text)
        #expect(passages.allSatisfy { $0.count <= 800 })
        #expect(passages.joined() == text)
        #expect(ReadingLanePolicy.boundedSource(String(repeating: "a", count: 60_000)).count == 50_000)
    }

    @Test("Word boundaries are preferred only in the second half of a full passage")
    func preservesWordBoundaries() {
        let a = { String(repeating: "a", count: $0) }
        let b = { String(repeating: "b", count: $0) }
        #expect(ReadingLanePolicy.passages(a(399) + " " + b(801)) == [a(399) + " " + b(400), b(401)])
        #expect(ReadingLanePolicy.passages(a(400) + " " + b(800)) == [a(400), b(800)])
        #expect(ReadingLanePolicy.passages(a(799) + " " + b(401)) == [a(799), b(401)])
        #expect(ReadingLanePolicy.passages(a(800) + " " + b(400)) == [a(800), b(400)])
        #expect(ReadingLanePolicy.passages(a(800)) == [a(800)])
    }

    @Test("Splitting trims Unicode whitespace while retaining combining marks and internal line breaks")
    func preservesUnicodeTrimming() {
        let prefix = String(repeating: "学", count: 800)
        let suffix = "e\u{301}👨‍👩‍👧‍👦\n第二行"
        #expect(ReadingLanePolicy.passages("\t" + prefix + "\u{2003}\u{00A0}\t" + suffix + "\u{2003}") == [prefix, suffix])
        #expect(ReadingLanePolicy.passages(prefix + " \u{301}text") == [prefix, "\u{301}text"])
    }

    @Test("Maximum-length Unicode input is preserved and overflow is excluded from the final passage")
    func splitsMaximumInput() {
        let source = String(repeating: "👨‍👩‍👧‍👦学e\u{301}🇨🇳", count: 12_500)
        let passages = ReadingLanePolicy.passages(source + "excluded")
        #expect(passages.count == 63)
        #expect(passages.dropLast().allSatisfy { $0.count == 800 })
        #expect(passages.last?.count == 400)
        #expect(passages.joined() == source)
    }

    @Test("Reading advances only on request and completes exactly once at the end")
    func progresses() {
        var session = ReadingLaneSession()
        #expect(session.start(source: " ") == false)
        #expect(session.start(source: "One\n\nTwo") == true)
        #expect(session.currentPassage == "One")
        #expect(session.previous() == false)
        #expect(session.advance() == true)
        #expect(session.currentPassage == "Two")
        #expect(session.readCount == 1)
        #expect(session.advance() == true)
        #expect(session.isComplete)
        #expect(session.readCount == 2)
        #expect(session.advance() == false)
        #expect(session.previous() == true)
        #expect(session.currentPassage == "Two")
        #expect(!session.isComplete)
    }

    @Test("Returning to the source preserves it and replacing it resets the reading position")
    @MainActor
    func retainsSessionSource() {
        let service = ReadingLaneService()
        service.updateSource("One\n\nTwo")
        #expect(service.start())
        service.advance()
        service.editSource()
        #expect(service.source == "One\n\nTwo")
        #expect(!service.session.isStarted)
        service.updateSource("New")
        #expect(service.start())
        #expect(service.session.currentPassage == "New")
        service.clear()
        #expect(service.source.isEmpty)
        #expect(!service.session.isStarted)
    }
}
