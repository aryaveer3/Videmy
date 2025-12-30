//
//  SharedDataManager.swift
//  Video Progress Tracker
//
//  Manages shared data between main app, widget, and share extension
//

import Foundation
import SwiftData

/// App Group identifier for sharing data between app, widget, and share extension
let appGroupIdentifier = "group.com.aryaveer.videoprogress"

// MARK: - Shared Data Models (Codable for UserDefaults sharing)

struct WidgetData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalWatchTime: Double // in seconds
    var totalCourses: Int
    var completedCourses: Int
    var totalVideos: Int
    var completedVideos: Int
    var lastUpdated: Date
    var recentCourses: [WidgetCourseData]
    
    static var empty: WidgetData {
        WidgetData(
            currentStreak: 0,
            longestStreak: 0,
            totalWatchTime: 0,
            totalCourses: 0,
            completedCourses: 0,
            totalVideos: 0,
            completedVideos: 0,
            lastUpdated: Date(),
            recentCourses: []
        )
    }
    
    var formattedWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        let minutes = (Int(totalWatchTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var overallProgress: Double {
        guard totalVideos > 0 else { return 0 }
        return Double(completedVideos) / Double(totalVideos)
    }
}

struct WidgetCourseData: Codable, Identifiable {
    var id: UUID
    var title: String
    var thumbnailURL: String
    var progress: Double // 0-1
    var videosCompleted: Int
    var totalVideos: Int
}

// MARK: - Shared URL Data (for Share Extension)

struct SharedURLData: Codable {
    var url: String
    var title: String?
    var addedAt: Date
    
    init(url: String, title: String? = nil) {
        self.url = url
        self.title = title
        self.addedAt = Date()
    }
}

// MARK: - Shared Data Manager

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Widget Data
    
    private let widgetDataKey = "widget_data"
    
    func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        userDefaults?.set(encoded, forKey: widgetDataKey)
    }
    
    func loadWidgetData() -> WidgetData {
        guard let data = userDefaults?.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return decoded
    }
    
    /// Update widget data from SwiftData models
    func updateWidgetData(courses: [Course], settings: UserSettings?) {
        let completedCourses = courses.filter { $0.completedPercentage >= 100 }.count
        let allVideos = courses.flatMap { $0.videos }
        let completedVideos = allVideos.filter { $0.isCompleted }.count
        
        let recentCourses = courses
            .sorted { $0.lastAccessedAt > $1.lastAccessedAt }
            .prefix(3)
            .map { course in
                WidgetCourseData(
                    id: course.id,
                    title: course.title,
                    thumbnailURL: course.thumbnailURL,
                    progress: (course.completedPercentage.isNaN ? 0 : course.completedPercentage) / 100,
                    videosCompleted: course.completedVideosCount,
                    totalVideos: course.videos.count
                )
            }
        
        let widgetData = WidgetData(
            currentStreak: settings?.currentStreak ?? 0,
            longestStreak: settings?.longestStreak ?? 0,
            totalWatchTime: settings?.totalWatchTime ?? 0,
            totalCourses: courses.count,
            completedCourses: completedCourses,
            totalVideos: allVideos.count,
            completedVideos: completedVideos,
            lastUpdated: Date(),
            recentCourses: Array(recentCourses)
        )
        
        saveWidgetData(widgetData)
    }
    
    // MARK: - Shared URLs (from Share Extension)
    
    private let sharedURLsKey = "shared_urls"
    
    func addSharedURL(_ urlData: SharedURLData) {
        var urls = loadSharedURLs()
        urls.append(urlData)
        
        guard let encoded = try? JSONEncoder().encode(urls) else { return }
        userDefaults?.set(encoded, forKey: sharedURLsKey)
    }
    
    func loadSharedURLs() -> [SharedURLData] {
        guard let data = userDefaults?.data(forKey: sharedURLsKey),
              let decoded = try? JSONDecoder().decode([SharedURLData].self, from: data) else {
            return []
        }
        return decoded
    }
    
    func clearSharedURLs() {
        userDefaults?.removeObject(forKey: sharedURLsKey)
    }
    
    func removeSharedURL(at index: Int) {
        var urls = loadSharedURLs()
        guard index < urls.count else { return }
        urls.remove(at: index)
        
        guard let encoded = try? JSONEncoder().encode(urls) else { return }
        userDefaults?.set(encoded, forKey: sharedURLsKey)
    }
}
