//
//  ContentView.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 04/11/2024.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .animation(.default, value: viewModel.state)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
            case .loading:
                loadingView
            case .loaded(let items):
                listViewFor(items: items)
            case .error(let errorState):
                alertView(content: errorState)
        }
    }
}

private extension HomeView {
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
    }

    func listViewFor(items: [Recipe]) -> some View {
        List(items) { recipe in
            NavigationLink {
                Text(recipe.name)
            } label: {
                Text(recipe.name)
            }
        }
    }

    private func alertView(content: AlertContent) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text(content.title)
                .font(.headline)

            Text(content.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(content.actions, id: \.title) { action in
                    Button(action.title) {
                        handleAction(action)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    func emptyStateView(title: String, subtitle: String?) -> some View {
        VStack (alignment: .center) {
            Image(systemName: Constant.UI.emptySFPath)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.placeholderApp)
            Text(title.localizedCapitalized)
                .font(.title)
                .foregroundColor(.placeholderApp)
            if let subtitle {
                Text(subtitle.localizedCapitalized)
                    .font(.title2)
                    .foregroundColor(.placeholderApp)
            }
        }
    }

    private func handleAction(_ action: AlertContent.AlertAction) {
        switch action {
            case .tryAgain:
                Task {
                    await viewModel.loadInitialData()
                }
            case .ok:
                break
        }
    }
}
