//
//  Video.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation
import SwiftData

@Model
final class Video {
    var id: UUID
    var youtubeId: String
    var title: String
    var duration: Double // in seconds
    var watchedDuration: Double // in seconds
    var isCompleted: Bool
    var lastWatchedTime: Double // timestamp in video
    var lastWatchedDate: Date
    var orderIndex: Int
    var thumbnailURL: String
    
    var course: Course?
    
    @Relationship(deleteRule: .cascade, inverse: \WatchSession.video)
    var watchSessions: [WatchSession]
    
    // Computed property for progress percentage
    var progressPercentage: Double {
        guard duration > 0, !duration.isNaN, !watchedDuration.isNaN else { return 0 }
        let percentage = (watchedDuration / duration) * 100
        return percentage.isNaN ? 0 : min(max(percentage, 0), 100)
    }
    
    // Formatted duration string
    var formattedDuration: String {
        let safeDuration = duration.isNaN || duration.isInfinite ? 0 : max(0, duration)
        let hours = Int(safeDuration) / 3600
        let minutes = (Int(safeDuration) % 3600) / 60
        let seconds = Int(safeDuration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Formatted watched duration
    var formattedWatchedDuration: String {
        let safeWatched = watchedDuration.isNaN || watchedDuration.isInfinite ? 0 : max(0, watchedDuration)
        let hours = Int(safeWatched) / 3600
        let minutes = (Int(safeWatched) % 3600) / 60
        let seconds = Int(safeWatched) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Thumbnail URL from YouTube ID
    var youtubeThumbnailURL: String {
        "https://img.youtube.com/vi/\(youtubeId)/mqdefault.jpg"
    }
    
    init(
        id: UUID = UUID(),
        youtubeId: String,
        title: String,
        duration: Double = 0,
        watchedDuration: Double = 0,
        isCompleted: Bool = false,
        lastWatchedTime: Double = 0,
        lastWatchedDate: Date = Date(),
        orderIndex: Int = 0,
        thumbnailURL: String = "",
        watchSessions: [WatchSession] = []
    ) {
        self.id = id
        self.youtubeId = youtubeId
        self.title = title
        self.duration = duration
        self.watchedDuration = watchedDuration
        self.isCompleted = isCompleted
        self.lastWatchedTime = lastWatchedTime
        self.lastWatchedDate = lastWatchedDate
        self.orderIndex = orderIndex
        self.thumbnailURL = thumbnailURL.isEmpty ? "https://img.youtube.com/vi/\(youtubeId)/mqdefault.jpg" : thumbnailURL
        self.watchSessions = watchSessions
    }
    
    // Update progress (called periodically during playback)
    func updateProgress(currentTime: Double) {
        lastWatchedTime = currentTime
        lastWatchedDate = Date()
        
        // Only update watched duration if we're watching further
        if currentTime > watchedDuration {
            watchedDuration = currentTime
        }
        
        // Check completion (90% threshold)
        if duration > 0 && watchedDuration >= duration * 0.9 {
            isCompleted = true
        }
    }
    
    // Mark as completed manually
    func markCompleted() {
        isCompleted = true
        watchedDuration = duration
    }
    
    // Mark as incomplete
    func markIncomplete() {
        isCompleted = false
    }
    
    // Reset progress
    func resetProgress() {
        watchedDuration = 0
        lastWatchedTime = 0
        isCompleted = false
    }
}
