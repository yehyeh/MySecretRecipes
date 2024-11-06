//
//  HomeService.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 04/11/2024.
//

import Foundation

enum HomeServiceError: Error {
    case secureAccess(Error?)
    case network(NetworkError)
}

protocol HomeServiceProtocol {
    var hasLockingPolicy: Bool { get }
    func fetchItems() async -> Result<[Recipe.Thumbnail], HomeServiceError>
    func accessDetails(for recipe: Recipe) async -> Result<UnlockedRecipe, HomeServiceError>
}

class HomeService: HomeServiceProtocol {
    private(set) var hasLockingPolicy: Bool = false
    private let networkManager: NetworkManagerProtocol
    private let secureAccessManager: SecureAccess
    private var securedDetails: [String: Data] = [:]

    init(networkManager: NetworkManagerProtocol = NetworkManager(), secureAccessManager: SecureAccess = SecureAccess()) {
        self.networkManager = networkManager
        self.secureAccessManager = secureAccessManager
    }

    func fetchItems() async -> Result<[Recipe.Thumbnail], HomeServiceError> {
        guard hasLockingPolicy else {
            return .failure(.secureAccess(SecureAccessError.notAvailable))
        }

        let networkResponse = await networkManager.request(.get,
                                                           path: Constant.Network.ApiEndPoint.recipes.path,
                                                           successType: [UnlockedRecipe].self)
        switch networkResponse {
            case .success(let recipes):
                let thumbnails = recipes.map(\.thumbnail)
                let detailItems = recipes.map(\.details)

                var securedData: [String: Data] = [:]
                for details in detailItems {
                    do {
                        securedData[details.id] = try await secureAccessManager.encryptRecipeDetails(details, for: details.id)
                    } catch {
                        return .failure(.secureAccess(error))
                    }
                }
                securedDetails = securedData
                return .success(thumbnails)

            case .failure(let error):
                return .failure(.network(error))
        }
    }

    func accessDetails(for recipe: Recipe.Thumbnail) async -> Result<UnlockedRecipe, HomeServiceError> {

        guard let securedData = securedDetails[recipe.id] else {
            return .failure(.secureAccess(.none))
        }

        do {
            let details = try await secureAccessManager.decryptRecipeDetails(encryptedData: securedData, for: recipe.id)
        } catch {
            return .failure(.secureAccess(error))
        }
        let unlocked = UnlockedRecipe(thumbnail: recipe, details: details)
        return .success(unlocked)
    }
}

struct UnlockedRecipe: Codable, Identifiable {
    let thumbnail: Recipe.Thumbnail
    let details: Recipe.Details

    var id: String { thumbnail.id }

    init(from decoder: Decoder) throws {
        thumbnail = try Recipe.Thumbnail(from: decoder)
        details = try Recipe.Details(from: decoder)
    }

    init(thumbnail: Recipe.Thumbnail, details: Recipe.Details) {
        self.thumbnail = thumbnail
        self.details = details
    }
}
