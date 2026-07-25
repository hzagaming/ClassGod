import Foundation

struct HelperPeerPolicy {
    static func allowedUID(
        arguments: [String],
        environment: [String: String],
        consoleUID: uid_t? = consoleUserUID()
    ) -> uid_t? {
        if let flagIndex = arguments.firstIndex(of: "--allowed-uid") {
            let valueIndex = arguments.index(after: flagIndex)
            guard valueIndex < arguments.endIndex,
                  let value = UInt32(arguments[valueIndex]) else { return nil }
            return uid_t(value)
        }

        if let value = environment["SUDO_UID"], let uid = UInt32(value) {
            return uid_t(uid)
        }
        return consoleUID
    }

    static func consoleUserUID() -> uid_t? {
        var info = stat()
        guard stat("/dev/console", &info) == 0, info.st_uid > 0 else { return nil }
        return info.st_uid
    }
}
