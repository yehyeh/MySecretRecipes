//
//  HomeViewModel.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

enum HomeViewState {
    case loading
    case loaded([Recipe.Thumbnail])
    case error(AlertContent)
}

class HomeViewModel: ObservableObject {
    @Published private(set) var state: HomeViewState = .loading
    @Published private(set) var isProcessing: Bool = false
    @Published var alertContent: AlertContent? = nil
    @Published var selectedItem: UnlockedRecipe? = nil

    private let homeService: HomeServiceProtocol

    init(homeService: HomeServiceProtocol = HomeService(secureStorageManager: SecureStorageManager<Recipe.Details>.manager())) {
        self.homeService = homeService
    }

    @MainActor
    func loadInitialData() {
        state = .loading
        Task {
            let result = await homeService.fetchItems()
            await MainActor.run {
                switch result {
                    case .success(let data):
                        state = .loaded(data)
                    case .failure(let error):
                        state = .error(AlertContent.map(serviceError: error))
                }
            }
        }
    }

    @MainActor
    func showDetailsFor(item: Recipe.Thumbnail) {
        isProcessing = true
        Task {
            let result = await homeService.unlockDetails(for: item)
            await MainActor.run {
                isProcessing = false
                switch result {
                    case .success(let unlockedItem):
                        selectedItem = unlockedItem

                    case .failure(let error):
                        alertContent = AlertContent.map(serviceError: error)
                }
            }
        }
    }

    @MainActor
    func handleAlertAction(_ action: AlertContent.AlertAction) {
        switch action {
            case .tryAgain:
                loadInitialData()
            case .ok:
                break
        }
        alertContent = nil
    }
}

extension HomeViewState: Equatable {
    static func == (lhs: HomeViewState, rhs: HomeViewState) -> Bool {
        switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.loaded(let lhsData), .loaded(let rhsData)):
                return lhsData.count == rhsData.count
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
        }
    }
}

private extension AlertContent {
    static func map(serviceError error: HomeServiceError) -> AlertContent {
        switch error {
            case .secureStorage(_):
                return AlertContent(
                    title: "Something Went Wrong",
                    message: "Unable to process the data :\\",
                    actions: [.ok]
                )

            case .network(let err):
                return map(networkError: err)
        }
    }

    static func map(networkError error: NetworkError) -> AlertContent {
        switch error {
            case .connectivity:
                return AlertContent(
                    title: "No Internet Connection",
                    message: "Please check your internet connection and try again.",
                    actions: [.tryAgain]
                )

            case .httpStatus(_):
                return AlertContent(
                    title: "Server Error",
                    message: "Unexpected server response",
                    actions: [.tryAgain]
                )

            default:
                return AlertContent(
                    title: "Something Went Wrong",
                    message: "Unable to process the data :\\",
                    actions: [.ok]
                )
        }
    }
}
