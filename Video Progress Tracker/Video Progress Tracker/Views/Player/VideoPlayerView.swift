//
//  VideoPlayerView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData

struct VideoPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var settings: [UserSettings]
    
    let course: Course
    @State private var currentVideo: Video
    
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = false
    @State private var showControls: Bool = true
    @State private var controlsTimer: Timer?
    @State private var watchSession: WatchSession?
    @State private var lastSaveTime: Date = Date()
    @State private var playerKey: UUID = UUID() // Force player recreation when video changes
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    init(video: Video, course: Course) {
        self.course = course
        self._currentVideo = State(initialValue: video)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(1, geometry.size.width)
            let safeHeight = max(1, geometry.size.height)
            let playerHeight = max(200, min(safeWidth * 9/16, safeHeight * 0.4))
            
            ZStack {
                // Liquid gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95),
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Player - uses key to force recreation when video changes
                    YouTubePlayerView(
                        videoId: currentVideo.youtubeId,
                        startTime: currentVideo.lastWatchedTime.isNaN ? 0 : currentVideo.lastWatchedTime,
                        currentTime: $currentTime,
                        duration: $duration,
                        isPlaying: $isPlaying,
                        onTimeUpdate: { time, dur in
                            handleTimeUpdate(currentTime: time, duration: dur)
                        },
                        onStateChange: { state in
                            handleStateChange(state)
                        },
                        onReady: {
                            handlePlayerReady()
                        }
                    )
                    .id(playerKey)
                    .frame(height: playerHeight.isNaN || playerHeight.isInfinite ? 200 : playerHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    
                    // Video Info & Controls
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Video Title
                            Text(currentVideo.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            // Progress Info
                            VideoProgressCard(
                                currentTime: currentTime,
                                duration: duration > 0 ? duration : currentVideo.duration,
                                isCompleted: currentVideo.isCompleted
                            )
                            
                            // Course Info
                            CourseInfoCard(course: course, currentVideo: currentVideo)
                            
                            // Video List - with callback to switch videos
                            VideoListSection(
                                course: course,
                                currentVideo: currentVideo,
                                onVideoSelected: { selectedVideo in
                                    switchToVideo(selectedVideo)
                                }
                            )
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        currentVideo.markCompleted()
                    } label: {
                        Label("Mark as Completed", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        currentVideo.resetProgress()
                    } label: {
                        Label("Reset Progress", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            startWatchSession()
            updateLastWatched()
        }
        .onDisappear {
            saveProgress()
            endWatchSession()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                saveProgress()
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePlayerReady() {
        if currentVideo.duration == 0 && duration > 0 {
            currentVideo.duration = duration
            course.updateTotalDuration()
        }
    }
    
    private func handleTimeUpdate(currentTime: Double, duration: Double) {
        // Guard against NaN and infinite values
        let safeCurrentTime = currentTime.isNaN || currentTime.isInfinite ? 0 : currentTime
        let safeDuration = duration.isNaN || duration.isInfinite ? 0 : duration
        
        self.currentTime = safeCurrentTime
        self.duration = safeDuration
        
        // Update video duration if not set
        if currentVideo.duration == 0 && safeDuration > 0 {
            currentVideo.duration = safeDuration
            course.updateTotalDuration()
        }
        
        // Auto-save every 5 seconds
        if Date().timeIntervalSince(lastSaveTime) >= 5 {
            saveProgress()
        }
    }
    
    private func handleStateChange(_ state: YouTubePlayerState) {
        isPlaying = state == .playing
        
        if state == .ended {
            currentVideo.markCompleted()
            saveProgress()
            
            // Auto-play next video
            playNextVideo()
        }
    }
    
    // MARK: - Video Switching
    
    private func switchToVideo(_ newVideo: Video) {
        guard newVideo.id != currentVideo.id else { return }
        
        // Save progress for current video
        saveProgress()
        endWatchSession()
        
        // Switch to new video
        currentVideo = newVideo
        currentTime = 0
        duration = 0
        
        // Force player recreation
        playerKey = UUID()
        
        // Start new watch session
        startWatchSession()
        updateLastWatched()
    }
    
    private func playNextVideo() {
        let sortedVideos = course.videos.sorted { $0.orderIndex < $1.orderIndex }
        guard let currentIndex = sortedVideos.firstIndex(where: { $0.id == currentVideo.id }),
              currentIndex + 1 < sortedVideos.count else { return }
        
        let nextVideo = sortedVideos[currentIndex + 1]
        switchToVideo(nextVideo)
    }
    
    // MARK: - Progress Management
    
    private func saveProgress() {
        currentVideo.updateProgress(currentTime: currentTime)
        lastSaveTime = Date()
        
        // Update user settings
        if let settings = userSettings {
            settings.lastWatchedCourseId = course.id
            settings.lastWatchedVideoId = currentVideo.id
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    private func startWatchSession() {
        let session = WatchSession(startTime: currentVideo.lastWatchedTime)
        session.video = currentVideo
        modelContext.insert(session)
        watchSession = session
    }
    
    private func endWatchSession() {
        guard let session = watchSession else { return }
        
        let watchedSeconds = max(0, currentTime - session.startTime)
        session.endSession(at: currentTime, watchedSeconds: watchedSeconds)
        
        // Update total watch time
        if let settings = userSettings {
            settings.addWatchTime(watchedSeconds)
            settings.updateStreak()
        }
        
        try? modelContext.save()
    }
    
    private func updateLastWatched() {
        course.markAccessed()
        
        // Ensure user settings exist
        if userSettings == nil {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
        }
        
        if let settings = userSettings {
            settings.lastWatchedCourseId = course.id
            settings.lastWatchedVideoId = currentVideo.id
        }
    }
}

// MARK: - Video Progress Card

struct VideoProgressCard: View {
    let currentTime: Double
    let duration: Double
    let isCompleted: Bool
    
    private var progress: Double {
        guard duration > 0, !duration.isNaN, !currentTime.isNaN else { return 0 }
        let value = currentTime / duration
        return value.isNaN ? 0 : min(max(value, 0), 1.0)
    }
    
    private var safeCurrentTime: Double {
        currentTime.isNaN || currentTime.isInfinite ? 0 : currentTime
    }
    
    private var safeDuration: Double {
        duration.isNaN || duration.isInfinite || duration <= 0 ? 0 : duration
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                
                Spacer()
                
                if isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
            
            // Liquid progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isCompleted ? [.green, .green.opacity(0.8)] : [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0, min(progress, 1.0)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(formatTime(safeCurrentTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatTime(safeDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else {
            return "0:00"
        }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Course Info Card

struct CourseInfoCard: View {
    let course: Course
    let currentVideo: Video
    
    private var currentIndex: Int {
        course.videos.sorted { $0.orderIndex < $1.orderIndex }
            .firstIndex(where: { $0.id == currentVideo.id }) ?? 0
    }
    
    private var safeProgress: Double {
        let value = course.completedPercentage / 100
        return value.isNaN || value.isInfinite ? 0 : min(max(value, 0), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                    
                    Text("Video \(currentIndex + 1) of \(course.videos.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Course progress badge
                Text("\(Int(course.completedPercentage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Liquid progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * safeProgress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: safeProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - Video List Section

struct VideoListSection: View {
    let course: Course
    let currentVideo: Video
    var onVideoSelected: ((Video) -> Void)?
    
    private var sortedVideos: [Video] {
        course.videos.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course Videos")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(sortedVideos) { video in
                    Button {
                        if video.id != currentVideo.id {
                            onVideoSelected?(video)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Status indicator
                            ZStack {
                                if video.id == currentVideo.id {
                                    Circle()
                                        .fill(.blue.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                } else if video.isCompleted {
                                    Circle()
                                        .fill(.green.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                } else if video.watchedDuration > 0 {
                                    CircularProgressView(progress: video.progressPercentage / 100)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .strokeBorder(Color(.systemGray4), lineWidth: 1.5)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(video.title)
                                    .font(.subheadline)
                                    .fontWeight(video.id == currentVideo.id ? .semibold : .regular)
                                    .lineLimit(2)
                                    .foregroundStyle(video.id == currentVideo.id ? .blue : .primary)
                                
                                Text(video.formattedDuration)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if video.id != currentVideo.id {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(video.id == currentVideo.id)
                    
                    if video.id != sortedVideos.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        VideoPlayerView(
            video: Video(youtubeId: "dQw4w9WgXcQ", title: "Sample Video"),
            course: Course(title: "Sample Course")
        )
    }
    .modelContainer(for: [Course.self, Video.self, WatchSession.self, UserSettings.self], inMemory: true)
}
