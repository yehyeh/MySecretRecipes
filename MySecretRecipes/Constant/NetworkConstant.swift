//
//  NetworkConstant.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

extension Constant {

    class Network {

        enum ApiEndPoint {

            case recipes

            var path: String {
                switch self {
                    case .recipes:
                        return "https://hf-android-app.s3-eu-west-1.amazonaws.com/android-test/recipes.json"
                }
            }
        }
    }
}
