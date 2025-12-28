//
//  FavoritesViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import UIKit
import Combine
import Kingfisher

protocol PodcastSelectionDelegate: AnyObject {
    func didSelectPodcast(_ podcast: Podcast)
}

final class FavoritesViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: FavoritesViewModel
    private var cancellables = Set<AnyCancellable>()
    weak var coordinator: PodcastSelectionDelegate?
    
    private var customView: FavoritesView {
        return self.view as! FavoritesView
    }
    
    // MARK: - Init
    init(viewModel: FavoritesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Favorites"
        self.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = FavoritesView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.customView.updateState(state)
            }
            .store(in: &cancellables)
        
        viewModel.$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.customView.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteCell.reuseIdentifier, for: indexPath) as? FavoriteCell else {
                fatalError("Could not dequeue FavoriteCell")
            }
            
            let podcast = viewModel.podcasts[indexPath.row]
            cell.configure(with: podcast)
            
            return cell
        }
}

// MARK: - UITableViewDelegate
extension FavoritesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let favorite = viewModel.podcasts[indexPath.row]
        
        let podcastModel = Podcast(
            trackId: Int(favorite.id),
            artistName: favorite.author ?? "Unknown",
            collectionName: favorite.title ?? "Unknown",
            artworkUrl100: favorite.coverUrl ?? "",
            feedUrl: nil,
            artworkUrl600: favorite.coverUrl,
            primaryGenreName: "Podcast"
        )
        
        coordinator?.didSelectPodcast(podcastModel)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.removePodcast(at: indexPath.row)
    
        }
    }
}
