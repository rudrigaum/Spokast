//
//  FavoritesViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import UIKit
import Combine

@MainActor
protocol PodcastSelectionDelegate: AnyObject {
    func didSelectPodcast(_ podcast: Podcast)
}

final class FavoritesViewController: UIViewController {
    
    // MARK: - Dependencies
    private let viewModel: FavoritesViewModelProtocol
    weak var coordinator: PodcastSelectionDelegate?
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var podcasts: [SavedPodcast] = []
    
    private var customView: FavoritesView {
        return self.view as! FavoritesView
    }
    
    // MARK: - Init
    
    init(viewModel: FavoritesViewModelProtocol? = nil) {
        self.viewModel = viewModel ?? FavoritesViewModel()
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Library"
        self.tabBarItem = UITabBarItem(
            title: "Library",
            image: UIImage(systemName: "books.vertical"),
            selectedImage: UIImage(systemName: "books.vertical.fill")
        )
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
        setupTableView()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
    }
    
    private func setupBindings() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Handling
    private func handleStateChange(_ state: FavoritesViewState) {
        switch state {
        case .loading:
            break
            
        case .empty:
            self.podcasts = []
            customView.tableView.reloadData()
            
        case .loaded(let items):
            self.podcasts = items
            customView.tableView.reloadData()
            
        case .error(let message):
            self.podcasts = []
            customView.tableView.reloadData()
            print("Error state: \(message)")
        }
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteCell.reuseIdentifier, for: indexPath) as? FavoriteCell else {
            return UITableViewCell()
        }
        
        let podcast = podcasts[indexPath.row]
        cell.configure(with: podcast)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FavoritesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let savedPodcast = podcasts[indexPath.row]
    
        let domainPodcast = Podcast(
            trackId: savedPodcast.collectionId,
            collectionId: savedPodcast.collectionId,
            artistName: savedPodcast.artistName,
            collectionName: savedPodcast.collectionName,
            artworkUrl100: savedPodcast.artworkUrl600 ?? "", 
            feedUrl: savedPodcast.feedUrl,
            artworkUrl600: savedPodcast.artworkUrl600,
            primaryGenreName: savedPodcast.primaryGenreName
        )
        
        coordinator?.didSelectPodcast(domainPodcast)
    }
    
    // Desabilitamos DELETE por enquanto
    /*
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // viewModel.removePodcast(at: indexPath.row)
        }
    }
    */
}
