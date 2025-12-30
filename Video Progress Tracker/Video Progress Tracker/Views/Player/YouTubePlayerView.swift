//
//  YouTubePlayerView.swift
//  Video Progress Tracker
//
//  Uses YouTube-Player-iOS-Helper (Google's official library)
//

import SwiftUI
import YouTubeiOSPlayerHelper

// MARK: - YouTube Player State

enum YouTubePlayerState: Int {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case cued = 5
    
    init(from ytState: YTPlayerState) {
        switch ytState {
        case .unstarted: self = .unstarted
        case .ended: self = .ended
        case .playing: self = .playing
        case .paused: self = .paused
        case .buffering: self = .buffering
        case .cued: self = .cued
        @unknown default: self = .unstarted
        }
    }
}

// MARK: - YouTube Player View (SwiftUI Wrapper)

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    let startTime: Double
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isPlaying: Bool
    
    var onTimeUpdate: ((Double, Double) -> Void)?
    var onStateChange: ((YouTubePlayerState) -> Void)?
    var onReady: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.delegate = context.coordinator
        
        // Store reference in coordinator for cleanup
        context.coordinator.playerView = playerView
        
        // Player variables for inline playback and better control
        let playerVars: [String: Any] = [
            "playsinline": 1,
            "start": Int(max(0, startTime)),
            "rel": 0,
            "modestbranding": 1,
            "controls": 1,
            "fs": 1,
            "enablejsapi": 1,
            "iv_load_policy": 3
        ]
        
        playerView.load(withVideoId: videoId, playerVars: playerVars)
        
        return playerView
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        // Updates handled via delegate
    }
    
    static func dismantleUIView(_ uiView: YTPlayerView, coordinator: Coordinator) {
        // Clean up when view is removed to prevent WebKit warnings
        coordinator.stopProgressTimer()
        uiView.stopVideo()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, YTPlayerViewDelegate {
        var parent: YouTubePlayerView
        weak var playerView: YTPlayerView?
        private var progressTimer: Timer?
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        // MARK: - YTPlayerViewDelegate
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            self.playerView = playerView
            
            // Get initial duration
            playerView.duration { [weak self] duration, error in
                if error == nil {
                    let safeDuration = duration.isNaN || duration.isInfinite ? 0 : duration
                    Task { @MainActor in
                        self?.parent.duration = safeDuration
                    }
                }
            }
            
            Task { @MainActor [weak self] in
                self?.parent.onReady?()
            }
            
            startProgressTimer()
        }
        
        func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
            let mappedState = YouTubePlayerState(from: state)
            
            Task { @MainActor [weak self] in
                self?.parent.isPlaying = state == .playing
                self?.parent.onStateChange?(mappedState)
            }
            
            switch state {
            case .playing:
                startProgressTimer()
            case .paused, .ended:
                stopProgressTimer()
                updateProgress()
            default:
                break
            }
        }
        
        func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
            let safeTime = Double(playTime)
            guard !safeTime.isNaN && !safeTime.isInfinite else { return }
            
            Task { @MainActor [weak self] in
                self?.parent.currentTime = safeTime
            }
        }
        
        func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
            var errorMessage: String
            
            switch error {
            case .invalidParam:
                errorMessage = "Invalid video ID"
            case .html5Error:
                errorMessage = "HTML5 playback error"
            case .videoNotFound:
                errorMessage = "Video not found or private"
            case .notEmbeddable:
                errorMessage = "Video owner disabled embedding"
            @unknown default:
                errorMessage = "Unknown error"
            }
            
            print("YouTube Player Error: \(errorMessage)")
        }
        
        // MARK: - Progress Tracking
        
        func startProgressTimer() {
            stopProgressTimer()
            progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        }
        
        func stopProgressTimer() {
            progressTimer?.invalidate()
            progressTimer = nil
        }
        
        private func updateProgress() {
            guard let playerView = playerView else { return }
            
            playerView.currentTime { [weak self] time, error in
                guard error == nil else { return }
                let safeTime = time.isNaN || time.isInfinite ? 0 : time
                
                playerView.duration { duration, durError in
                    guard durError == nil else { return }
                    let safeDuration = duration.isNaN || duration.isInfinite ? 0 : duration
                    
                    Task { @MainActor in
                        self?.parent.currentTime = Double(safeTime)
                        self?.parent.duration = safeDuration
                        self?.parent.onTimeUpdate?(Double(safeTime), safeDuration)
                    }
                }
            }
        }
        
        deinit {
            stopProgressTimer()
        }
    }
}

// MARK: - Player Controller

@MainActor
class YouTubePlayerController: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published var playbackRate: Float = 1.0
    
    private weak var playerView: YTPlayerView?
    
    func setPlayerView(_ playerView: YTPlayerView) {
        self.playerView = playerView
    }
    
    func play() {
        playerView?.playVideo()
    }
    
    func pause() {
        playerView?.pauseVideo()
    }
    
    func seek(to time: Double) {
        playerView?.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
    
    func setRate(_ rate: Float) {
        playbackRate = rate
        playerView?.setPlaybackRate(rate)
    }
}

// MARK: - Delegate Adapter (for compatibility)

class YouTubePlayerDelegateAdapter {
    var onTimeUpdate: ((Double, Double) -> Void)?
    var onStateChange: ((YouTubePlayerState) -> Void)?
    var onReady: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init(
        onTimeUpdate: ((Double, Double) -> Void)? = nil,
        onStateChange: ((YouTubePlayerState) -> Void)? = nil,
        onReady: (() -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.onTimeUpdate = onTimeUpdate
        self.onStateChange = onStateChange
        self.onReady = onReady
        self.onError = onError
    }
}
