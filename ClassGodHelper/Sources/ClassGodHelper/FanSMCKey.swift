struct FanSMCKey: Hashable {
    let index: Int

    init?(_ actualRPMKey: String) {
        let bytes = Array(actualRPMKey.utf8)
        guard bytes.count == 4,
              bytes[0] == Character("F").asciiValue,
              bytes[2] == Character("A").asciiValue,
              bytes[3] == Character("c").asciiValue,
              let index = Int(String(UnicodeScalar(bytes[1])), radix: 16) else { return nil }
        self.index = index
    }

    static func actualRPMKey(for index: Int) -> String? {
        guard (0...15).contains(index) else { return nil }
        return "F\(String(index, radix: 16, uppercase: true))Ac"
    }

    func key(suffix: String) -> String? {
        guard suffix.utf8.count == 2 else { return nil }
        return "F\(String(index, radix: 16, uppercase: true))\(suffix)"
    }
}
