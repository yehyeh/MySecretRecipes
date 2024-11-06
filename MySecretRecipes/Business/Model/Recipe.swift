//
//  Recipe.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

enum Recipe {
    struct Thumbnail: Codable, Identifiable {
        let id: String
        let name: String
        let thumb: String
        let fats: String
        let calories: String
        let carbos: String
    }

    struct Details: Codable {
        let id: String
        let description: String
        let difficulty: Int
        let headline: String
        let image: String
        let proteins: String
        let time: String
        let country: String?
    }
}
