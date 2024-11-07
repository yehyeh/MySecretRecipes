//
//  HomeView.swift
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
        NavigationStack {
            ZStack {
                content

                if viewModel.isProcessing {
                    ZStack {
                        Color.dynamicText.opacity(0.5)
                        ProgressView()
                    }
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("My Secret Recipes".localizedCapitalized)
            .animation(.default, value: viewModel.state)
            .onAppear {
                Task {
                    viewModel.loadInitialData()
                }
            }
            .sheet(item: $viewModel.selectedItem) { item in
                DetailsView(recipe: item)
            }
            .alert(item: $viewModel.alertContent) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
            case .loading:
                loadingView
            case .loaded(let items):
                listViewFor(items: items)
            case .error(let errorState):
                emptyStateView(title: errorState.title, subtitle: errorState.message)
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

    func listViewFor(items: [Recipe.Thumbnail]) -> some View {
        List(items) { item in
            Text(item.name)
                .onTapGesture {
                    viewModel.showDetailsFor(item: item)
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

            Button("Try Again") {
                viewModel.loadInitialData()
            }
        }
    }
}
