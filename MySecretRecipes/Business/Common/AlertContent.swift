//
//  AlertContent.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import SwiftUI

struct AlertContent: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actions: [AlertAction]

    enum AlertAction {
        case tryAgain
        case ok

        var title: String {
            switch self {
                case .tryAgain: return "Try Again"
                case .ok: return "OK"
            }
        }
    }
}

extension AlertContent: Equatable {
    static func == (lhs: AlertContent, rhs: AlertContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions.elementsEqual(rhs.actions) { $0.title == $1.title }
    }
}
