//
//  PodcastDetailViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation
import UIKit
import Kingfisher
import Combine

final class PodcastDetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: PodcastDetailViewModel
    private var customView: PodcastDetailView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(viewModel: PodcastDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.customView = PodcastDetailView()
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customView?.tableView.dataSource = self
        setupConfiguration()
        setupBindings()
        viewModel.fetchEpisodes()
    }
    
    // MARK: - Configuration
    private func setupConfiguration() {
        guard let customView = customView else { return }
        
        customView.configure(with: viewModel)
        
        if let url = viewModel.coverImageURL {
            customView.imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        }
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                guard let self = self else { return }
                
                if !episodes.isEmpty {
                    print("🚀 SUCESSO! Recebemos \(episodes.count) episódios.")
                    self.customView?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        // Observa erros
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let _ = self else { return }
                print("❌ ERRO: \(message)")
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension PodcastDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath)
        let episode = viewModel.episodes[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = episode.trackName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: episode.releaseDate)
        
        content.secondaryText = dateString
        content.secondaryTextProperties.color = .secondaryLabel
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}
