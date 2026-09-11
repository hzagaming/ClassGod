import Foundation
import Testing
@testable import ClassGod

@Suite("Nettop stream parsing")
struct NettopTests {
    private let header = "time,,bytes_in,bytes_out,\n"

    @Test("Startup cumulative totals are discarded and the first delta sample is published")
    func skipsCumulativeSample() {
        var snapshots: [NettopSnapshot] = []
        let parser = NettopCSVParser { snapshots.append($0) }
        parser.feed(Data((header + "12:00:00,App.42,999999,888888,\n" + header).utf8))
        #expect(snapshots.isEmpty)
        parser.feed(Data(("12:00:01,App.42,12,34,\n" + header).utf8))
        #expect(snapshots.count == 1)
        #expect(snapshots.last?.processes[42]?.deltaIn == 12)
        #expect(snapshots.last?.processes[42]?.deltaOut == 34)
    }

    @Test("Every possible pipe split preserves Unicode rows, headers, and delta values")
    func handlesArbitraryChunkBoundaries() {
        let stream = Data((header + "12:00:00,App.42,500,600,\n" + header
            + "12:00:01,学习.工具👨‍👩‍👧‍👦.42,12,34,\n" + header).utf8)
        for boundary in 0...stream.count {
            var snapshots: [NettopSnapshot] = []
            let parser = NettopCSVParser { snapshots.append($0) }
            parser.feed(stream.prefix(boundary))
            parser.feed(stream.dropFirst(boundary))
            #expect(snapshots.last?.processes[42]?.deltaIn == 12)
            #expect(snapshots.last?.processes[42]?.deltaOut == 34)
        }
    }

    @Test("Single-byte input retains multibyte characters and waits for complete lines")
    func handlesSingleBytes() {
        var snapshots: [NettopSnapshot] = []
        let parser = NettopCSVParser { snapshots.append($0) }
        let stream = header + header + "12:00:01,笔记.7,23,45,\n" + String(header.dropLast())
        for byte in stream.utf8 { parser.feed(Data([byte])) }
        #expect(snapshots.isEmpty)
        parser.feed(Data([10]))
        #expect(snapshots.count == 1)
        #expect(snapshots.last?.processes[7]?.deltaIn == 23)
    }

    @Test("An empty delta sample clears values for processes that are no longer present")
    func publishesEmptySamples() {
        var snapshots: [NettopSnapshot] = []
        let parser = NettopCSVParser { snapshots.append($0) }
        parser.feed(Data((header + header + "12:00:01,App.42,12,34,\n" + header).utf8))
        parser.feed(Data(header.utf8))
        #expect(snapshots.count == 2)
        #expect(snapshots.first?.processes[42]?.deltaIn == 12)
        #expect(snapshots.last?.processes.isEmpty == true)
    }

    @Test("Malformed rows and invalid UTF-8 do not discard neighboring valid process rows")
    func recoversAfterInvalidRows() {
        var snapshots: [NettopSnapshot] = []
        let parser = NettopCSVParser { snapshots.append($0) }
        var data = Data((header + header + "12:00:01,App.1,5,6,\n").utf8)
        data.append(contentsOf: [0xFF, 0xFE, 10])
        data.append(Data(("bad row\n12:00:01,App.2,-1,2,\n12:00:01,App.3,18446744073709551616,2,\n"
            + "12:00:01,App.bad,1,2,\n12:00:01, App.With Dots.4 , \(UInt64.max) , 9 ,\n" + header).utf8))
        parser.feed(data)
        #expect(snapshots.count == 1)
        #expect(snapshots.last?.processes.count == 2)
        #expect(snapshots.last?.processes[1]?.deltaOut == 6)
        #expect(snapshots.last?.processes[4]?.deltaIn == UInt64.max)
    }

    @Test("Leading control bytes and spaces are accepted on sample headers")
    func acceptsHeaderControls() {
        var snapshots: [NettopSnapshot] = []
        let parser = NettopCSVParser { snapshots.append($0) }
        parser.feed(Data(("\u{04}\u{08} " + header + header + "12:00:01,App.9,1,2,\n" + header).utf8))
        #expect(snapshots.count == 1)
        #expect(snapshots.last?.processes[9]?.deltaOut == 2)
    }
}
