import CoreAudio
import Foundation

enum QuietAudioHardware {
    static func defaultOutput() -> QuietDevice? {
        guard let id = integer(AudioObjectID(kAudioObjectSystemObject), selector: kAudioHardwarePropertyDefaultOutputDevice),
              id != kAudioObjectUnknown,
              let uid = string(id, selector: kAudioDevicePropertyDeviceUID), !uid.isEmpty else { return nil }
        return QuietDevice(uid: uid, name: string(id, selector: kAudioObjectPropertyName) ?? uid)
    }

    static func readMute(_ device: QuietDevice) -> Bool? {
        guard let id = resolve(device.uid), canMute(id),
              let value = integer(id, selector: kAudioDevicePropertyMute, scope: kAudioObjectPropertyScopeOutput) else { return nil }
        return value != 0
    }

    static func writeMute(_ device: QuietDevice, _ muted: Bool) -> Bool {
        guard let id = resolve(device.uid), canMute(id),
              string(id, selector: kAudioDevicePropertyDeviceUID) == device.uid else { return false }
        var address = address(kAudioDevicePropertyMute, scope: kAudioObjectPropertyScopeOutput)
        var value: UInt32 = muted ? 1 : 0
        return AudioObjectSetPropertyData(id, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr
    }

    private static func resolve(_ uid: String) -> AudioDeviceID? {
        guard !uid.isEmpty else { return nil }
        var address = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr,
              size > 0, size <= 16_384, Int(size) % MemoryLayout<AudioDeviceID>.size == 0 else { return nil }
        var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        let result = devices.withUnsafeMutableBytes {
            AudioObjectGetPropertyData(system, &address, 0, nil, &size, $0.baseAddress!)
        }
        guard result == noErr else { return nil }
        return devices.prefix(Int(size) / MemoryLayout<AudioDeviceID>.size).first {
            string($0, selector: kAudioDevicePropertyDeviceUID) == uid
        }
    }

    private static func canMute(_ id: AudioDeviceID) -> Bool {
        var address = address(kAudioDevicePropertyMute, scope: kAudioObjectPropertyScopeOutput)
        var settable: DarwinBoolean = false
        return AudioObjectHasProperty(id, &address)
            && AudioObjectIsPropertySettable(id, &address, &settable) == noErr && settable.boolValue
    }

    private static func integer(_ id: AudioObjectID, selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> UInt32? {
        var address = address(selector, scope: scope)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
              size == MemoryLayout<UInt32>.size else { return nil }
        return value
    }

    private static func string(_ id: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
        var address = address(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }

    private static func address(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
