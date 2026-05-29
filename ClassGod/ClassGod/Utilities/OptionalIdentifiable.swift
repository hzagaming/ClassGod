//
//  OptionalIdentifiable.swift
//  ClassGod
//

import Foundation

// Conditional Identifiable conformance for Optional, needed for SettingsPickerRow with Optional<BrowserType>
extension Optional: Identifiable where Wrapped: Identifiable {
    public var id: Wrapped.ID? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.id
        }
    }
}
