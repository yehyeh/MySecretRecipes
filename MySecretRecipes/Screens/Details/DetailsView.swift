//
//  DetailsView.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 06/11/2024.
//

import SwiftUI

struct DetailsView: View {
    let recipe: UnlockedRecipe

    init(recipe: UnlockedRecipe) {
        self.recipe = recipe
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: recipe.details.image)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }

                Text(recipe.details.headline)
                    .font(.title)
                    .fontWeight(.bold)

                Text(recipe.details.description)

                HStack {
                    Text("Difficulty: \(recipe.details.difficulty)/5")
                    Spacer()
                    Text("Prep Time: \(recipe.details.time)")
                }

                HStack {
                    Text("Proteins: \(recipe.details.proteins)")
                    Spacer()
                    Text("Fats: \(recipe.thumbnail.fats)")
                }

                HStack {
                    Text("Carbs: \(recipe.thumbnail.carbos)")
                    Spacer()
                    Text("Calories: \(recipe.thumbnail.calories)")
                }

                if let country = recipe.details.country {
                    Text("Country: \(country)")
                }

                Spacer()
            }
            .padding()
        }
    }
}
