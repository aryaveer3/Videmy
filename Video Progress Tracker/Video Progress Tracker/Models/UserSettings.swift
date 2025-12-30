//
//  UserSettings.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var lastWatchedCourseId: UUID?
    var lastWatchedVideoId: UUID?
    var totalWatchTime: Double // in seconds
    var currentStreak: Int
    var lastWatchDate: Date?
    var longestStreak: Int
    
    init(
        id: UUID = UUID(),
        lastWatchedCourseId: UUID? = nil,
        lastWatchedVideoId: UUID? = nil,
        totalWatchTime: Double = 0,
        currentStreak: Int = 0,
        lastWatchDate: Date? = nil,
        longestStreak: Int = 0
    ) {
        self.id = id
        self.lastWatchedCourseId = lastWatchedCourseId
        self.lastWatchedVideoId = lastWatchedVideoId
        self.totalWatchTime = totalWatchTime
        self.currentStreak = currentStreak
        self.lastWatchDate = lastWatchDate
        self.longestStreak = longestStreak
    }
    
    // Update streak based on watch activity
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastWatch = lastWatchDate {
            let lastWatchDay = calendar.startOfDay(for: lastWatch)
            let daysDifference = calendar.dateComponents([.day], from: lastWatchDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day, streak continues
            } else if daysDifference == 1 {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First time watching
            currentStreak = 1
        }
        
        lastWatchDate = Date()
    }
    
    // Add watch time
    func addWatchTime(_ seconds: Double) {
        totalWatchTime += seconds
    }
    
    // Formatted total watch time
    var formattedTotalWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        let minutes = (Int(totalWatchTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
