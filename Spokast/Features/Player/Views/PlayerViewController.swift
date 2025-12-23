//
//  PlayerViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import UIKit
import Combine
import Kingfisher

final class PlayerViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: PlayerViewModel
    private var customView: PlayerView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.customView = PlayerView()
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        guard let customView = customView else { return }

        customView.playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        customView.forwardButton.addTarget(self, action: #selector(didTapForward), for: .touchUpInside)
        customView.rewindButton.addTarget(self, action: #selector(didTapRewind), for: .touchUpInside)
    }
    
    // MARK: - Actions Handlers
    @objc private func didTapPlayPause() {
        viewModel.didTapPlayPause()
    }
    
    @objc private func didTapForward() {
        viewModel.didTapForward()
    }
    
    @objc private func didTapRewind() {
        viewModel.didTapRewind()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        guard let customView = customView else { return }
        
        bindHeaderData(to: customView)
        bindCoverImage(to: customView)
        bindPlayerState(to: customView)
    }
    
    private func bindHeaderData(to view: PlayerView) {
        Publishers.CombineLatest(viewModel.$title, viewModel.$artist)
            .receive(on: DispatchQueue.main)
            .sink { [weak view] (title, artist) in
                view?.configure(title: title, artist: artist)
            }
            .store(in: &cancellables)
    }
    
    private func bindCoverImage(to view: PlayerView) {
        viewModel.$coverURL
            .receive(on: DispatchQueue.main)
            .sink { [weak view] url in
                view?.coverImageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(systemName: "music.note"),
                    options: [.transition(.fade(0.3))]
                )
            }
            .store(in: &cancellables)
    }
    
    private func bindPlayerState(to view: PlayerView) {
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak view] isPlaying in
                view?.updatePlayButtonState(isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }
}
