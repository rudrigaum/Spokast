//
//  MainTabBarController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import UIKit
import Combine

final class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    private let miniPlayerViewModel: MiniPlayerViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView(viewModel: miniPlayerViewModel)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    // MARK: - Init
    init(viewControllers: [UIViewController]) {
        self.miniPlayerViewModel = MiniPlayerViewModel()
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = viewControllers
        setupAppearance()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMiniPlayerLayout()
        setupBindings()
        setupActions()
        AudioPlayerService.shared.restoreLastState()
    }
    
    // MARK: - Setup UI
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemPurple
    }
    
    private func setupMiniPlayerLayout() {
        view.addSubview(miniPlayerView)
        view.bringSubviewToFront(tabBar)
        
        let playerHeight: CGFloat = 64
        
        NSLayoutConstraint.activate([
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: playerHeight),
            miniPlayerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
    }
    
    // MARK: - Actions
    private func setupActions() {
        miniPlayerView.onTap = { [weak self] in
            self?.presentPlayer()
        }
    }
    
    private func presentPlayer() {
        guard let currentEpisode = AudioPlayerService.shared.currentEpisode else {
            print("⚠️ Nenhum episódio selecionado no AudioService")
            return
        }
        
        let currentImageURL = AudioPlayerService.shared.currentPodcastImageURL
        let favoritesRepository = FavoritesRepository()
        
        let playerVM = PlayerViewModel(
            episode: currentEpisode,
            podcastImageURL: currentImageURL,
            favoritesRepository: favoritesRepository
        )
        
        let playerVC = PlayerViewController(viewModel: playerVM)
        playerVC.modalPresentationStyle = .automatic
        
        self.present(playerVC, animated: true)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        miniPlayerViewModel.$isVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                self?.animatePlayer(show: shouldShow)
            }
            .store(in: &cancellables)
    }
    
    private func animatePlayer(show: Bool) {
        guard miniPlayerView.isHidden == show else { return }
        
        if show {
            miniPlayerView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.miniPlayerView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.miniPlayerView.alpha = 0
            }) { _ in
                self.miniPlayerView.isHidden = true
            }
        }
    }
}
