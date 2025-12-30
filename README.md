# [App Name] 🎙️

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-lightgrey.svg)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Combine-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

> A modern, fully programmatic iOS Podcast Player built with **Clean Code** principles and reactive programming.

---

## 📱 Overview

**[App Name]** is a native iOS application designed to provide a seamless podcast listening experience. It features a robust **Global Mini Player**, real-time playback synchronization, and a highly responsive UI built entirely programmatically (View Code).

The goal of this project is to demonstrate advanced iOS development skills, including reactive state management with **Combine**, SOLID principles, and a modular architecture.

## ✨ Key Features

* **Global Mini Player:** A persistent playback control that floats above the interface, allowing users to browse while listening.
* **Reactive UI:** Real-time UI updates (Play/Pause states, progress bars) synchronized across screens using Combine.
* **Audio Streaming:** efficient handling of remote audio files via `AVFoundation`.
* **Image Caching:** Optimized image loading for podcast artwork using **Kingfisher**.
* **Programmatic UI:** 100% View Code (No Storyboards/Xibs) for better version control and performance.

## 📸 Screenshots

| Home & List | Global Mini Player | Player Detail |
|:---:|:---:|:---:|
| <img src="docs/home.png" width="250"> | <img src="docs/miniplayer.png" width="250"> | <img src="docs/player.png" width="250"> |

*(Note: Add your actual screenshots or GIFs in a `docs` folder)*

## 🛠 Tech Stack

* **Language:** Swift 5
* **Frameworks:** UIKit, AVFoundation, Combine
* **Architecture:** MVVM (Model-View-ViewModel)
* **UI Layout:** Auto Layout (Programmatic Constraints)
* **Dependency Management:** Swift Package Manager (SPM)
* **External Libraries:** * [Kingfisher](https://github.com/onevcat/Kingfisher) (Async Image Loading)

## 🏗 Architecture & Design Decisions

This project follows a strict **MVVM** pattern to separate logic from UI configuration.

### 1. Reactive Bindings with Combine
Instead of the traditional Delegate pattern, this app uses `Combine` for data binding. 
* **Example:** The `MiniPlayerView` observes the `PlayerService` state. When the audio state changes, the UI reacts instantly without manual refresh triggers.

```swift
// Example of the clean binding approach used in the project
viewModel.$isPlaying
    .receive(on: DispatchQueue.main)
    .sink { [weak self] isPlaying in
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        self?.updatePlayButton(with: iconName)
    }
    .store(in: &cancellables)
