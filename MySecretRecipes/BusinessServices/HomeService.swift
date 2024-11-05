//
//  HomeService.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 04/11/2024.
//

import Foundation

protocol HomeServiceProtocol {
    func fetchHomeItems() async -> Result<[Recipe], NetworkError>
}

class HomeService: HomeServiceProtocol {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol = NetworkManager()) {
        self.networkManager = networkManager
    }

    func fetchHomeItems() async -> Result<[Recipe], NetworkError> {
        await
        networkManager.request(.get,
                               path: Constant.Network.ApiEndPoint.recipes.path,
                               successType: [Recipe].self)
    }
}
