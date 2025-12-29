//
//  SearchViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import UIKit
import Combine

final class SearchViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: SearchViewModel
    private var cancellables = Set<AnyCancellable>()
    weak var coordinator: PodcastSelectionDelegate?
    
    // MARK: - UI Components
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Find podcasts, artists..."
        sc.searchBar.tintColor = .systemPurple
        return sc
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.register(PodcastCell.self, forCellReuseIdentifier: PodcastCell.reuseIdentifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No results found."
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        setupUI()
        setupBindings()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "Search"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        bindSearchInput()
        bindViewModelOutputs()
    }
    
    private func bindSearchInput() {
        NotificationCenter.default.publisher(
            for: UISearchTextField.textDidChangeNotification,
            object: searchController.searchBar.searchTextField
        )
        .map { ($0.object as! UISearchTextField).text ?? "" }
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .removeDuplicates()
        .sink { [weak self] text in
            self?.handleSearchInput(text)
        }
        .store(in: &cancellables)
    }
    
    private func bindViewModelOutputs() {
        viewModel.$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateViewForState(state)
            }
            .store(in: &cancellables)
    }
        
    private func handleSearchInput(_ text: String) {
        if text.isEmpty {
            viewModel.resetSearch()
        } else {
            viewModel.executeSearch(for: text)
        }
    }
    
    // MARK: - View State Management
    private func updateViewForState(_ state: SearchViewState) {
        switch state {
        case .idle:
            setLayoutState(showTable: false, showLoader: false, showError: false)
            
        case .loading:
            setLayoutState(showTable: false, showLoader: true, showError: false)
            
        case .success:
            setLayoutState(showTable: true, showLoader: false, showError: false)
            
        case .empty:
            setLayoutState(showTable: false, showLoader: false, showError: true)
            emptyLabel.text = "No results found for \"\(searchController.searchBar.text ?? "")\""
            
        case .error(let message):
            setLayoutState(showTable: false, showLoader: false, showError: true)
            emptyLabel.text = message
        }
    }
    
    private func setLayoutState(showTable: Bool, showLoader: Bool, showError: Bool) {
        tableView.isHidden = !showTable
        emptyLabel.isHidden = !showError
        
        if showLoader {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - TableView DataSource
extension SearchViewController: UITableViewDataSource {
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

// MARK: - TableView Delegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let podcast = viewModel.podcasts[indexPath.row]
        coordinator?.didSelectPodcast(podcast)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
