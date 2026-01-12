//
//  DownloadButton.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 07/01/26.
//

import Foundation
import UIKit

final class DownloadButton: UIButton {
    
    // MARK: - Enums
    enum State {
        case notDownloaded
        case downloading(progress: Float)
        case downloaded
    }
    
    // MARK: - UI Layers
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private let checkmarkLayer = CAShapeLayer() // 1. Nova Layer
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayers()
        updateState(.notDownloaded)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let centerPoint = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let smallestDimension = min(bounds.width, bounds.height)
        let radius = (smallestDimension / 2) - 2
        
        let circularPath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
            clockwise: true
        )
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: bounds.width * 0.35, y: bounds.height * 0.5))
        checkPath.addLine(to: CGPoint(x: bounds.width * 0.45, y: bounds.height * 0.65))
        checkPath.addLine(to: CGPoint(x: bounds.width * 0.70, y: bounds.height * 0.35))
        
        checkmarkLayer.path = checkPath.cgPath
        checkmarkLayer.frame = bounds
    }
    
    // MARK: - Public API
    func updateState(_ state: State) {
        resetVisualState()
        
        switch state {
        case .notDownloaded:
            progressLayer.isHidden = true
            checkmarkLayer.isHidden = true
            setupNotDownloaded()
            
        case .downloading(let progress):
            setupDownloading(progress: progress)
            
        case .downloaded:
            setupDownloaded()
        }
    }
        
    // MARK: - Private Helpers
    private func resetVisualState() {
        trackLayer.isHidden = true
        progressLayer.isHidden = true
        checkmarkLayer.isHidden = true
        progressLayer.strokeEnd = 0
        imageView?.layer.removeAllAnimations()
    }
    
    private func setupNotDownloaded() {
        setButtonIcon(name: "arrow.down", color: .label)
    }
    
    private func setupDownloading(progress: Float) {
        setButtonIcon(name: "stop.fill", color: .systemPurple)
        
        trackLayer.isHidden = false
        progressLayer.isHidden = false
        checkmarkLayer.isHidden = true
        progressLayer.strokeEnd = CGFloat(progress)
    }
    
    private func setupDownloaded() {
        setImage(nil, for: .normal)
        trackLayer.isHidden = true
        progressLayer.isHidden = true
        checkmarkLayer.isHidden = false
    }
    
    private func setButtonIcon(name: String, color: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let image = UIImage(systemName: name, withConfiguration: config)
        setImage(image, for: .normal)
        tintColor = color
    }
    
    // MARK: - Setup
    private func setupLayers() {
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = 3
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        
        progressLayer.strokeColor = UIColor.systemPurple.cgColor
        progressLayer.lineWidth = 3
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        checkmarkLayer.strokeColor = UIColor.systemGreen.cgColor
        checkmarkLayer.lineWidth = 3
        checkmarkLayer.fillColor = UIColor.clear.cgColor
        checkmarkLayer.lineCap = .round
        checkmarkLayer.lineJoin = .round
        checkmarkLayer.isHidden = true
        layer.addSublayer(checkmarkLayer)
    }
    
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
