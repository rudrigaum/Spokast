//
//  HomeViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class HomeViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: HomeViewModel
    private var homeView: HomeView?

    // MARK: - Initialization
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func loadView() {
        self.homeView = HomeView()
        self.view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        homeView?.podcastsTableView.dataSource = self
        viewModel.fetchPodcasts()
    }

    private func setupView() {
        title = "Spokast"
    }
}

// MARK: - HomeViewModelDelegate
extension HomeViewController: HomeViewModelDelegate {

    func didFetchPodcastsSuccessfully() {
        homeView?.podcastsTableView.reloadData()
        print("Successfully fetched podcasts!")
    }

    func didFailToFetchPodcasts(with error: String) {
        print("Failed to fetch podcasts with error: \(error)")
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastCell.reuseIdentifier, for: indexPath) as? PodcastCell else {
            return UITableViewCell()
        }
        
        let podcast = viewModel.podcasts[indexPath.row]
        
        cell.configure(
            title: podcast.collectionName,
            publisher: podcast.artistName,
            imageUrlString: podcast.artworkUrl100
        )
        
        return cell
    }
}
