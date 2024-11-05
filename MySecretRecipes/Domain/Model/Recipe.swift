//
//  Recipe.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

struct Recipe: Codable, Identifiable {
    let id: String
    let image: String
    //description: String
    let name: String
    let thumb: String
    let fats: String
    let calories: String
    let carbos: String
}

typealias Recipes = [Recipe]

/*
/// Used only required: "name", "thumb", "fats", "calories" and "carbos"
struct Recipe: Codable {
    let calories, carbos, description: String
    let difficulty: Int
    let fats, headline, id: String
    let image: String
    let name, proteins: String
    let thumb: String
    let time: String
    let country: String?
}
*/
