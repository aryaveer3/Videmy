//
//  WatchSession.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation
import SwiftData

@Model
final class WatchSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var watchedSeconds: Double
    var startTime: Double // Where in the video playback started
    var endTime: Double // Where in the video playback ended
    
    var video: Video?
    
    // Session duration
    var sessionDuration: TimeInterval {
        guard let endedAt = endedAt else {
            return Date().timeIntervalSince(startedAt)
        }
        return endedAt.timeIntervalSince(startedAt)
    }
    
    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        watchedSeconds: Double = 0,
        startTime: Double = 0,
        endTime: Double = 0
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.watchedSeconds = watchedSeconds
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // End the session
    func endSession(at time: Double, watchedSeconds: Double) {
        self.endedAt = Date()
        self.endTime = time
        self.watchedSeconds = watchedSeconds
    }
}
