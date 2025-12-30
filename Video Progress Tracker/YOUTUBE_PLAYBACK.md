# Video Progress Tracker - YouTube Playback

## Current Implementation
The app uses a custom WKWebView-based YouTube player with the YouTube iFrame API. This is a dependency-free solution that works for most videos.

## Why Videos May Not Play

### 1. **Embedding Disabled (Error 101/150)**
Some YouTube creators disable embedding for their videos. This is a restriction set by the video owner and **cannot be bypassed** by any app. The only solution is to watch directly on YouTube.

### 2. **Video Private/Deleted (Error 100)**
The video may have been made private, deleted, or is region-restricted.

---

## Recommended Libraries for Better YouTube Playback

### Option 1: YouTubePlayerKit (Recommended)
**GitHub:** https://github.com/nicklockwood/YouTubePlayerKit

A modern, SwiftUI-first YouTube player library.

**Add via Swift Package Manager:**
1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/nicklockwood/YouTubePlayerKit`
3. Add to your target

**Usage:**
```swift
import YouTubePlayerKit

struct PlayerView: View {
    let youTubePlayer = YouTubePlayer(
        source: .video(id: "VIDEO_ID"),
        configuration: .init(autoPlay: true)
    )
    
    var body: some View {
        YouTubePlayerView(youTubePlayer)
    }
}
```

### Option 2: XCDYouTubeKit
**GitHub:** https://github.com/nicklockwood/XCDYouTubeKit

Extracts direct video URLs (bypasses some embed restrictions).

**Note:** This extracts direct MP4/WebM URLs which may violate YouTube ToS for some use cases.

**Add via SPM:**
```
https://github.com/nicklockwood/XCDYouTubeKit
```

### Option 3: youtube-ios-player-helper (Google Official)
**GitHub:** https://github.com/nicklockwood/youtube-ios-player-helper

Google's official Objective-C library (can be used with Swift).

**Add via CocoaPods:**
```ruby
pod 'youtube-ios-player-helper', '~> 1.0'
```

---

## Adding YouTubePlayerKit to This Project

1. Open `Video Progress Tracker.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter: `https://github.com/nicklockwood/YouTubePlayerKit`
4. Click **Add Package**
5. Replace the current `YouTubePlayerView.swift` with:

```swift
import SwiftUI
import YouTubePlayerKit

struct YouTubePlayerViewWrapper: View {
    let videoId: String
    let startTime: Double
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isPlaying: Bool
    
    @StateObject private var youTubePlayer: YouTubePlayer
    
    init(videoId: String, startTime: Double, currentTime: Binding<Double>, duration: Binding<Double>, isPlaying: Binding<Bool>) {
        self.videoId = videoId
        self.startTime = startTime
        self._currentTime = currentTime
        self._duration = duration
        self._isPlaying = isPlaying
        
        let config = YouTubePlayer.Configuration(
            autoPlay: false,
            startTime: Int(startTime),
            showControls: true,
            showRelatedVideos: false
        )
        self._youTubePlayer = StateObject(wrappedValue: YouTubePlayer(source: .video(id: videoId), configuration: config))
    }
    
    var body: some View {
        YouTubePlayerView(youTubePlayer)
            .onReceive(youTubePlayer.currentTimePublisher()) { time in
                currentTime = time
            }
            .onReceive(youTubePlayer.durationPublisher()) { dur in
                duration = dur ?? 0
            }
            .onReceive(youTubePlayer.statePublisher()) { state in
                isPlaying = state == .playing
            }
    }
}
```

---

## Troubleshooting

### Video shows "Embedding disabled"
→ The video owner has disabled embedding. Watch on YouTube.

### Video doesn't load at all
→ Check network connection.

### Player stuck on "Loading..."
→ YouTube API may be blocked. Check if `youtube.com` is accessible.
