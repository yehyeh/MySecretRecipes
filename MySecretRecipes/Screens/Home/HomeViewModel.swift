//
//  HomeViewModel.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

enum HomeViewState {
    case loading
    case loaded([Recipe])
    case error(AlertContent)
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

extension AlertContent {
    static func map(_ error: NetworkError) -> AlertContent {
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

class HomeViewModel: ObservableObject {
    @Published private(set) var state: HomeViewState = .loading

    private let homeService: HomeServiceProtocol

    init(homeService: HomeServiceProtocol = HomeService()) {
        self.homeService = homeService
        Task {
            await loadInitialData()
        }
    }

    @MainActor
    func loadInitialData() async {
        state = .loading

        let result = await homeService.fetchHomeItems()
        switch result {
            case .success(let data):
                state = .loaded(data)
            case .failure(let error):
                state = .error(AlertContent.map(error))
        }
    }
}
