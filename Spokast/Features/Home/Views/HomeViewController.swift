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
    private let homeViewModel: HomeViewModel
    private let searchViewModel: SearchViewModel

    private let searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: HomeViewControllerDelegate?

    private var customView: HomeView {
        guard let customView = view as? HomeView else {
            fatalError(
                "Expected view to be of type HomeView. "
                + "Verify your loadView() method implementation."
            )
        }

        return customView
    }

    // MARK: - UI Components
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(
            searchResultsController: nil
        )

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search podcasts, creators..."

        return searchController
    }()

    // MARK: - Initialization
    init(
        homeViewModel: HomeViewModel,
        searchViewModel: SearchViewModel
    ) {
        self.homeViewModel = homeViewModel
        self.searchViewModel = searchViewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func loadView() {
        view = HomeView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupCollectionView()
        setupSearch()
        setupBindings()

        homeViewModel.fetchHomeData()
    }

    // MARK: - Setup
    private func setupNavigation() {
        title = "Discover"

        definesPresentationContext = true
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupCollectionView() {
        customView.collectionView.dataSource = self
        customView.collectionView.delegate = self
    }

    private func setupSearch() {
        customView.searchResultsView.tableView.dataSource = self
        customView.searchResultsView.tableView.delegate = self
    }

    // MARK: - Bindings
    private func setupBindings() {
        bindHomeViewModel()
        bindSearchViewModel()
        bindSearchInput()
    }

    private func bindHomeViewModel() {
        homeViewModel.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleHomeStateChange(state)
            }
            .store(in: &cancellables)

        homeViewModel.$sections
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.customView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func bindSearchViewModel() {
        searchViewModel.$podcasts
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.customView.searchResultsView.tableView.reloadData()
            }
            .store(in: &cancellables)

        searchViewModel.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleSearchStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func bindSearchInput() {
        searchTextSubject
            .debounce(
                for: .milliseconds(500),
                scheduler: RunLoop.main
            )
            .removeDuplicates()
            .sink { [weak self] text in
                self?.handleSearchInput(text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Search
    private func handleSearchInput(_ text: String) {
        let query = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            searchViewModel.resetSearch()
            return
        }

        searchViewModel.executeSearch(for: query)
    }

    // MARK: - Home State
    private func handleHomeStateChange(_ state: HomeViewState) {
        switch state {
        case .loading:
            customView.showLoading(true)

        case .success:
            customView.showLoading(false)

        case .error(let message):
            customView.showLoading(false)

            showAlert(
                title: "Oops!",
                message: message,
                primaryButtonTitle: "Retry",
                secondaryButtonTitle: "Cancel",
                primaryAction: { [weak self] in
                    self?.homeViewModel.fetchHomeData()
                }
            )
        }
    }

    // MARK: - Search State
    private func handleSearchStateChange(_ state: SearchViewState) {
        switch state {
        case .idle:
            customView.searchResultsView.showIdle()

        case .loading:
            customView.searchResultsView.showLoading()

        case .success:
            customView.searchResultsView.showResults()

        case .empty:
            let query = searchController.searchBar.text ?? ""

            customView.searchResultsView.showMessage(
                "No results found for \"\(query)\"."
            )

        case .error(let message):
            customView.searchResultsView.showMessage(message)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension HomeViewController: UISearchResultsUpdating {

    func updateSearchResults(
        for searchController: UISearchController
    ) {
        let text = searchController.searchBar.text ?? ""
        searchTextSubject.send(text)
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        homeViewModel.sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        homeViewModel.sections[section].podcasts.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeaturedPodcastCell.reuseIdentifier,
            for: indexPath
        ) as? FeaturedPodcastCell else {
            fatalError("Could not dequeue FeaturedPodcastCell")
        }

        let section = homeViewModel.sections[indexPath.section]
        let podcast = section.podcasts[indexPath.item]

        cell.configure(with: podcast)

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: HomeSectionHeader.reuseIdentifier,
                  for: indexPath
              ) as? HomeSectionHeader else {
            return UICollectionReusableView()
        }

        let sectionTitle = homeViewModel.sections[indexPath.section].title

        header.configure(with: sectionTitle)

        return header
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(
            at: indexPath,
            animated: true
        )

        let section = homeViewModel.sections[indexPath.section]
        let podcast = section.podcasts[indexPath.item]

        delegate?.didSelectPodcast(podcast)
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        searchViewModel.podcasts.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PodcastCell.reuseIdentifier,
            for: indexPath
        ) as? PodcastCell else {
            return UITableViewCell()
        }

        let podcast = searchViewModel.podcasts[indexPath.row]

        cell.configure(
            title: podcast.collectionName ?? "Unknown Title",
            publisher: podcast.artistName ?? "Unknown Artist",
            imageUrlString: podcast.artworkUrl100 ?? ""
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        let podcast = searchViewModel.podcasts[indexPath.row]

        delegate?.didSelectPodcast(podcast)
    }
}
