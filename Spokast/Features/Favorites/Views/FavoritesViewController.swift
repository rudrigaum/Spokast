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

@MainActor
protocol PodcastSelectionDelegate: AnyObject {
    func didSelectPodcast(_ podcast: Podcast)
}

final class FavoritesViewController: UIViewController {
    
    // MARK: - Typealiases
    typealias DataSource = UICollectionViewDiffableDataSource<FavoritesSection, FavoriteItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<FavoritesSection, FavoriteItem>
    
    // MARK: - Dependencies
    private let viewModel: FavoritesViewModelProtocol
    weak var coordinator: PodcastSelectionDelegate?
    
    // MARK: - Properties
    private var dataSource: DataSource!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.backgroundColor = .systemGroupedBackground
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        return cv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Your library is empty.\nAdd podcasts via search."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        configureDataSource()
        setupBindings()
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupNavigation() {
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        filterButton.isEnabled = false
        navigationItem.rightBarButtonItem = filterButton
    }
    
    // MARK: - Menu Logic (Filtering)
    private func updateFilterMenu() {
        guard !viewModel.availableGenres.isEmpty else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        let showAllAction = UIAction(
            title: "All Categories",
            state: viewModel.currentFilter == nil ? .on : .off
        ) { [weak self] _ in
            self?.viewModel.filter(by: nil)
        }
        
        let genreActions = viewModel.availableGenres.map { genre in
            UIAction(
                title: genre,
                state: self.viewModel.currentFilter == genre ? .on : .off
            ) { [weak self] _ in
                self?.viewModel.filter(by: genre)
            }
        }

        let menu = UIMenu(
            title: "Filter by Genre",
            children: [showAllAction] + genreActions
        )
        
        navigationItem.rightBarButtonItem?.menu = menu
    }
    
    // MARK: - Diffable Data Source Configuration
    private func configureDataSource() {
        let cellRegistration = makeCellRegistration()
        let headerRegistration = makeHeaderRegistration()
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    // MARK: - Cell & Header Factories
    private func makeCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, FavoriteItem> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, FavoriteItem> { [weak self] cell, indexPath, item in
            
            var content = cell.defaultContentConfiguration()
            
            content.text = item.title
            content.secondaryText = item.artist
            
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
            content.secondaryTextProperties.color = .secondaryLabel
            
            content.image = UIImage(systemName: "mic.circle.fill")
            content.imageProperties.tintColor = .systemPurple
            content.imageProperties.maximumSize = CGSize(width: 50, height: 50)
            content.imageProperties.cornerRadius = 8
            
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            
            self?.loadImage(for: item, into: cell)
        }
    }
    
    private func makeHeaderRegistration() -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            
            let snapshot = self.dataSource.snapshot()
            let sections = snapshot.sectionIdentifiers
            
            if indexPath.section < sections.count {
                let section = sections[indexPath.section]
                var content = supplementaryView.defaultContentConfiguration()
                
                content.text = section.title
                content.textProperties.font = .preferredFont(forTextStyle: .title3)
                content.textProperties.color = .label
                
                supplementaryView.contentConfiguration = content
            }
        }
    }
    
    private func loadImage(for item: FavoriteItem, into cell: UICollectionViewListCell) {
        guard let urlString = item.artworkUrl, let url = URL(string: urlString) else { return }
        
        let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100))
                       |> RoundCornerImageProcessor(cornerRadius: 8)
        
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.3)),
            .cacheOriginalImage
        ]
        
        KingfisherManager.shared.retrieveImage(with: url, options: options) { [weak cell] result in
            DispatchQueue.main.async {
                guard let cell = cell else { return }
                switch result {
                case .success(let value):
                    if var updatedContent = cell.contentConfiguration as? UIListContentConfiguration {
                        updatedContent.image = value.image
                        cell.contentConfiguration = updatedContent
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: FavoritesViewState) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            collectionView.isHidden = true
            emptyLabel.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = false
            
        case .empty:
            loadingIndicator.stopAnimating()
            collectionView.isHidden = true
            emptyLabel.isHidden = false
            navigationItem.rightBarButtonItem?.isEnabled = false
            
        case .loaded(let sections):
            loadingIndicator.stopAnimating()
            collectionView.isHidden = false
            emptyLabel.isHidden = true
            
            updateFilterMenu()
            applySnapshot(sections)
            
        case .error(let message):
            loadingIndicator.stopAnimating()
            print("Error state: \(message)")
        }
    }
    
    private func applySnapshot(_ sections: [FavoritesSection]) {
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if let domainPodcast = viewModel.getPodcastDomainObject(at: indexPath) {
            coordinator?.didSelectPodcast(domainPodcast)
        }
    }
}
