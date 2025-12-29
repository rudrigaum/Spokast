//  HomeViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import UIKit
import Combine

protocol HomeViewControllerDelegate: AnyObject {
    func didSelectPodcast(_ podcast: Podcast)
}

final class HomeViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: HomeViewControllerDelegate?

    private var customView: HomeView {
        return self.view as! HomeView
    }

    // MARK: - Initialization
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func loadView() {
        self.view = HomeView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupCollectionView()
        setupBindings()
        viewModel.fetchHomeData()
    }

    // MARK: - Setup
    private func setupNavigation() {
        title = "Discover"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupCollectionView() {
        customView.collectionView.dataSource = self
        customView.collectionView.delegate = self
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.customView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: HomeViewState) {
        switch state {
        case .loading:
            customView.showLoading(true)
        case .success:
            customView.showLoading(false)
        case .error(let message):
            customView.showLoading(false)
            showErrorAlert(message: message)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.viewModel.fetchHomeData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.sections[section].podcasts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeaturedPodcastCell.reuseIdentifier, for: indexPath) as? FeaturedPodcastCell else {
            fatalError("Could not dequeue FeaturedPodcastCell")
        }
        
        let section = viewModel.sections[indexPath.section]
        let podcast = section.podcasts[indexPath.item]
        
        cell.configure(with: podcast)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeSectionHeader.reuseIdentifier, for: indexPath) as? HomeSectionHeader else {
                return UICollectionReusableView()
            }
            
            let sectionTitle = viewModel.sections[indexPath.section].title
            header.configure(with: sectionTitle)
            return header
        }
        
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let section = viewModel.sections[indexPath.section]
        let selectedPodcast = section.podcasts[indexPath.item]
        delegate?.didSelectPodcast(selectedPodcast)
    }
}
