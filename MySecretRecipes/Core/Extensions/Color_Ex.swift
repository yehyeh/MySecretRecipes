//
//  Color_Ex.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import SwiftUI

extension Color {
    static let dynamicBackground = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
    })

    static let dynamicText = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
    })

    /// App Defaults:
    static var tintApp: Color { .blue }
    static var placeholderApp: Color { .gray }
    static var starApp: Color { .yellow }
}
