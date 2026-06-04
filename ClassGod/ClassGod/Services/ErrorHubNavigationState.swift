//
//  ErrorHubNavigationState.swift
//  ClassGod
//
//  Shared navigation state for ErrorHub deep-linking from toasts.
//  Created by ClassGod on 2026/05/31.
//

import Foundation
import Combine

final class ErrorHubNavigationState: ObservableObject {
    static let shared = ErrorHubNavigationState()
    
    @Published var targetEntryID: UUID?
    
    private init() {}
    
    func navigateToEntry(id: UUID) {
        targetEntryID = id
        NotificationCenter.default.post(
            name: .classGodShowErrorHubEntry,
            object: nil,
            userInfo: ["entryID": id]
        )
    }
    
    func clearTarget() {
        targetEntryID = nil
    }
}
