import Foundation

struct HelperPeerPolicy {
    static func allowedUID(arguments: [String], environment: [String: String]) -> uid_t? {
        if let flagIndex = arguments.firstIndex(of: "--allowed-uid") {
            let valueIndex = arguments.index(after: flagIndex)
            guard valueIndex < arguments.endIndex,
                  let value = UInt32(arguments[valueIndex]) else { return nil }
            return uid_t(value)
        }

        guard let value = environment["SUDO_UID"],
              let uid = UInt32(value) else { return nil }
        return uid_t(uid)
    }
}
