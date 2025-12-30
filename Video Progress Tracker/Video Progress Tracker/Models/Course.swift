//
//  Course.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation
import SwiftData

@Model
final class Course {
    var id: UUID
    var title: String
    var thumbnailURL: String
    var totalDuration: Double // in seconds
    var createdAt: Date
    var lastAccessedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Video.course)
    var videos: [Video]
    
    // Computed property for completion percentage
    var completedPercentage: Double {
        guard !videos.isEmpty else { return 0 }
        let completedCount = videos.filter { $0.isCompleted }.count
        return (Double(completedCount) / Double(videos.count)) * 100
    }
    
    // Computed property for total watched duration
    var totalWatchedDuration: Double {
        videos.reduce(0) { $0 + $1.watchedDuration }
    }
    
    // Get the video to continue watching
    var continueWatchingVideo: Video? {
        // First, find incomplete videos sorted by last watched
        let incompleteVideos = videos
            .filter { !$0.isCompleted && $0.watchedDuration > 0 }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate }
        
        if let lastWatched = incompleteVideos.first {
            return lastWatched
        }
        
        // If no incomplete videos with progress, find the first unwatched
        return videos.first { !$0.isCompleted && $0.watchedDuration == 0 }
    }
    
    // Number of completed videos
    var completedVideosCount: Int {
        videos.filter { $0.isCompleted }.count
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        thumbnailURL: String = "",
        totalDuration: Double = 0,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        videos: [Video] = []
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.totalDuration = totalDuration
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.videos = videos
    }
    
    // Update total duration based on videos
    func updateTotalDuration() {
        totalDuration = videos.reduce(0) { $0 + $1.duration }
    }
    
    // Mark course as accessed
    func markAccessed() {
        lastAccessedAt = Date()
    }
}
