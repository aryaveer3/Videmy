//
//  CourseManager.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation
import SwiftData

@MainActor
class CourseManager: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var importProgress: Double = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Create Course from URL
    
    func createCourse(from urlString: String, title: String? = nil) async throws -> Course {
        isLoading = true
        errorMessage = nil
        importProgress = 0
        
        defer { isLoading = false }
        
        let urlType = YouTubeService.parseURL(urlString)
        
        switch urlType {
        case .video(let id):
            return try await createCourseFromVideo(videoId: id, title: title)
        case .playlist(let id, let videoIds):
            return try await createCourseFromPlaylist(playlistId: id, existingVideoIds: videoIds, title: title)
        case .invalid:
            throw YouTubeError.invalidURL
        }
    }
    
    // MARK: - Create from Single Video
    
    private func createCourseFromVideo(videoId: String, title: String?) async throws -> Course {
        let metadata = try await YouTubeService.fetchVideoMetadata(videoId: videoId)
        
        let course = Course(
            title: title ?? metadata.title,
            thumbnailURL: metadata.thumbnailURL
        )
        
        let video = Video(
            youtubeId: videoId,
            title: metadata.title,
            duration: metadata.duration,
            orderIndex: 0,
            thumbnailURL: metadata.thumbnailURL
        )
        
        course.videos.append(video)
        
        modelContext.insert(course)
        try modelContext.save()
        
        importProgress = 1.0
        
        return course
    }
    
    // MARK: - Create from Playlist
    
    private func createCourseFromPlaylist(playlistId: String, existingVideoIds: [String]?, title: String?) async throws -> Course {
        // First, try to get video IDs from the playlist
        var videoIds: [String] = []
        
        do {
            videoIds = try await YouTubeService.extractPlaylistVideoIds(playlistId: playlistId)
        } catch {
            // If playlist extraction fails, use any existing video IDs from URL
            if let existing = existingVideoIds, !existing.isEmpty {
                videoIds = existing
            } else {
                throw YouTubeError.playlistFetchFailed
            }
        }
        
        guard !videoIds.isEmpty else {
            throw YouTubeError.noVideosFound
        }
        
        // Create course
        let course = Course(
            title: title ?? "Imported Playlist"
        )
        
        // Fetch metadata for each video
        var videos: [Video] = []
        let totalVideos = Double(videoIds.count)
        
        for (index, videoId) in videoIds.enumerated() {
            do {
                let metadata = try await YouTubeService.fetchVideoMetadata(videoId: videoId)
                
                let video = Video(
                    youtubeId: videoId,
                    title: metadata.title,
                    duration: metadata.duration,
                    orderIndex: index,
                    thumbnailURL: metadata.thumbnailURL
                )
                
                videos.append(video)
                
                // Update course thumbnail with first video's thumbnail
                if index == 0 {
                    course.thumbnailURL = metadata.thumbnailURL
                    if title == nil {
                        course.title = "Playlist: \(metadata.title.components(separatedBy: " - ").first ?? metadata.title)"
                    }
                }
                
                importProgress = Double(index + 1) / totalVideos
                
                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
            } catch {
                // Continue with other videos even if one fails
                print("Failed to fetch metadata for video \(videoId): \(error)")
            }
        }
        
        guard !videos.isEmpty else {
            throw YouTubeError.noVideosFound
        }
        
        course.videos = videos
        course.updateTotalDuration()
        
        modelContext.insert(course)
        try modelContext.save()
        
        return course
    }
    
    // MARK: - Manual Course Creation
    
    func createManualCourse(title: String, videoURLs: [String]) async throws -> Course {
        isLoading = true
        errorMessage = nil
        importProgress = 0
        
        defer { isLoading = false }
        
        let course = Course(title: title)
        var videos: [Video] = []
        let totalURLs = Double(videoURLs.count)
        
        for (index, urlString) in videoURLs.enumerated() {
            let urlType = YouTubeService.parseURL(urlString)
            
            switch urlType {
            case .video(let videoId):
                do {
                    let metadata = try await YouTubeService.fetchVideoMetadata(videoId: videoId)
                    
                    let video = Video(
                        youtubeId: videoId,
                        title: metadata.title,
                        duration: metadata.duration,
                        orderIndex: index,
                        thumbnailURL: metadata.thumbnailURL
                    )
                    
                    videos.append(video)
                    
                    if index == 0 {
                        course.thumbnailURL = metadata.thumbnailURL
                    }
                    
                } catch {
                    // Create video with minimal info
                    let video = Video(
                        youtubeId: videoId,
                        title: "Video \(index + 1)",
                        orderIndex: index
                    )
                    videos.append(video)
                }
                
            default:
                continue
            }
            
            importProgress = Double(index + 1) / totalURLs
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        guard !videos.isEmpty else {
            throw YouTubeError.noVideosFound
        }
        
        course.videos = videos
        course.updateTotalDuration()
        
        modelContext.insert(course)
        try modelContext.save()
        
        return course
    }
    
    // MARK: - Add Video to Course
    
    func addVideo(to course: Course, urlString: String) async throws {
        let urlType = YouTubeService.parseURL(urlString)
        
        guard case .video(let videoId) = urlType else {
            throw YouTubeError.invalidURL
        }
        
        let metadata = try await YouTubeService.fetchVideoMetadata(videoId: videoId)
        
        let video = Video(
            youtubeId: videoId,
            title: metadata.title,
            duration: metadata.duration,
            orderIndex: course.videos.count,
            thumbnailURL: metadata.thumbnailURL
        )
        
        course.videos.append(video)
        course.updateTotalDuration()
        
        try modelContext.save()
    }
    
    // MARK: - Delete Course
    
    func deleteCourse(_ course: Course) throws {
        modelContext.delete(course)
        try modelContext.save()
    }
    
    // MARK: - Delete Video
    
    func deleteVideo(_ video: Video, from course: Course) throws {
        if let index = course.videos.firstIndex(where: { $0.id == video.id }) {
            course.videos.remove(at: index)
            course.updateTotalDuration()
        }
        modelContext.delete(video)
        try modelContext.save()
    }
    
    // MARK: - Update Video Order
    
    func reorderVideos(in course: Course, from source: IndexSet, to destination: Int) throws {
        var videos = course.videos.sorted { $0.orderIndex < $1.orderIndex }
        videos.move(fromOffsets: source, toOffset: destination)
        
        for (index, video) in videos.enumerated() {
            video.orderIndex = index
        }
        
        try modelContext.save()
    }
}
