//
//  Item.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 04/11/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
