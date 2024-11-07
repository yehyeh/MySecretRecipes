//
//  HomeService.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 04/11/2024.
//

import Foundation

enum HomeServiceError: Error {
    case secureStorage(SecurityError?)
    case network(NetworkError)
}

protocol HomeServiceProtocol {
    func fetchItems() async -> Result<[Recipe.Thumbnail], HomeServiceError>
    func unlockDetails(for thumbnail: Recipe.Thumbnail) async -> Result<UnlockedRecipe, HomeServiceError>
}

class HomeService: HomeServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let secureStorageManager: SecureStorageManager<Recipe.Details>
    private var securedDetails: [String: Data] = [:]

    init(networkManager: NetworkManagerProtocol = NetworkManager(),
         secureStorageManager: SecureStorageManager<Recipe.Details>) {
        self.networkManager = networkManager
        self.secureStorageManager = secureStorageManager
    }

    func fetchItems() async -> Result<[Recipe.Thumbnail], HomeServiceError> {
        let networkResponse = await networkManager.request(.get,
                                                           path: Constant.Network.ApiEndPoint.recipes.path,
                                                           successType: [UnlockedRecipe].self)
        switch networkResponse {
            case .success(let recipes):
                let thumbnails = recipes.map(\.thumbnail)
                let detailsItems = recipes.map(\.details)

                var securedDetailsNew: [String: Data] = [:]
                for details in detailsItems {
                    do {
                        securedDetailsNew[details.id] = try secureStorageManager.encrypt(details, with: details.id)
                    } catch {
                        return .failure(.secureStorage(.encryption))
                    }
                }
                securedDetails = securedDetailsNew
                return .success(thumbnails)

            case .failure(let error):
                return .failure(.network(error))
        }
    }

    func unlockDetails(for thumbnail: Recipe.Thumbnail) async -> Result<UnlockedRecipe, HomeServiceError> {
        do {
            let details = try await secureStorageManager.decrypt(itemId: thumbnail.id)
            let unlocked = UnlockedRecipe(thumbnail: thumbnail, details: details)
            return .success(unlocked)
        } catch {
            return .failure(.secureStorage(.decryption))
        }
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
