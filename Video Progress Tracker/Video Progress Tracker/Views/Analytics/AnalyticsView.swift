//
//  AnalyticsView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @Query private var settings: [UserSettings]
    @Query(sort: \WatchSession.startedAt, order: .reverse) private var watchSessions: [WatchSession]
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    // Computed analytics
    private var totalWatchTime: Double {
        userSettings?.totalWatchTime ?? watchSessions.reduce(0) { $0 + $1.watchedSeconds }
    }
    
    private var completedCourses: Int {
        courses.filter { $0.completedPercentage >= 100 }.count
    }
    
    private var inProgressCourses: Int {
        courses.filter { $0.completedPercentage > 0 && $0.completedPercentage < 100 }.count
    }
    
    private var totalVideosWatched: Int {
        courses.flatMap { $0.videos }.filter { $0.isCompleted }.count
    }
    
    private var totalVideos: Int {
        courses.flatMap { $0.videos }.count
    }
    
    private var currentStreak: Int {
        userSettings?.currentStreak ?? 0
    }
    
    private var longestStreak: Int {
        userSettings?.longestStreak ?? 0
    }
    
    // Weekly watch data
    private var weeklyWatchData: [DailyWatchData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayWatchTime = watchSessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .reduce(0) { $0 + $1.watchedSeconds }
            
            return DailyWatchData(date: date, watchTime: dayWatchTime / 60) // in minutes
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid background
                LiquidBackground()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Overview Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total Watch Time",
                                value: formatDuration(totalWatchTime),
                                icon: "clock.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Current Streak",
                                value: "\(currentStreak) days",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Courses Completed",
                                value: "\(completedCourses)/\(courses.count)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Videos Watched",
                                value: "\(totalVideosWatched)/\(totalVideos)",
                                icon: "play.rectangle.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        // Weekly Chart
                        WeeklyChartView(data: weeklyWatchData)
                            .padding(.horizontal)
                        
                        // Course Progress Overview
                        if !courses.isEmpty {
                            CourseProgressSection(courses: courses)
                                .padding(.horizontal)
                        }
                        
                        // Achievement Section
                        AchievementSection(
                            longestStreak: longestStreak,
                            completedCourses: completedCourses,
                            totalWatchTime: totalWatchTime
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analytics")
            .onAppear {
                ensureUserSettings()
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    private func ensureUserSettings() {
        if settings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
        }
    }
}

// MARK: - Data Models

struct DailyWatchData: Identifiable {
    let id = UUID()
    let date: Date
    let watchTime: Double // in minutes
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Weekly Chart View

struct WeeklyChartView: View {
    let data: [DailyWatchData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.dayName),
                    y: .value("Minutes", item.watchTime)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray5))
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Course Progress Section

struct CourseProgressSection: View {
    let courses: [Course]
    
    private var sortedCourses: [Course] {
        courses.sorted { $0.lastAccessedAt > $1.lastAccessedAt }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(sortedCourses.prefix(5)) { course in
                    let safeProgress = course.completedPercentage.isNaN ? 0 : max(0, min(100, course.completedPercentage))
                    
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 60, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            // Liquid mini progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: progressGradient(for: course),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * (safeProgress / 100))
                                }
                            }
                            .frame(height: 6)
                        }
                        
                        Text("\(Int(safeProgress))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(progressColor(for: course))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
    
    private func progressColor(for course: Course) -> Color {
        let safePercentage = course.completedPercentage.isNaN ? 0 : course.completedPercentage
        if safePercentage >= 100 {
            return .green
        } else if safePercentage > 0 {
            return .blue
        }
        return .gray
    }
    
    private func progressGradient(for course: Course) -> [Color] {
        let safePercentage = course.completedPercentage.isNaN ? 0 : course.completedPercentage
        if safePercentage >= 100 {
            return [.green, .green.opacity(0.8)]
        } else if safePercentage > 0 {
            return [.blue, .cyan]
        }
        return [.gray, .gray.opacity(0.8)]
    }
}

// MARK: - Achievement Section

struct AchievementSection: View {
    let longestStreak: Int
    let completedCourses: Int
    let totalWatchTime: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
            
            HStack(spacing: 12) {
                AchievementBadge(
                    icon: "flame.fill",
                    title: "Best Streak",
                    value: "\(longestStreak) days",
                    isUnlocked: longestStreak >= 3,
                    color: .orange
                )
                
                AchievementBadge(
                    icon: "trophy.fill",
                    title: "Courses Done",
                    value: "\(completedCourses)",
                    isUnlocked: completedCourses >= 1,
                    color: .yellow
                )
                
                AchievementBadge(
                    icon: "clock.fill",
                    title: "Study Time",
                    value: formatHours(totalWatchTime),
                    isUnlocked: totalWatchTime >= 3600,
                    color: .blue
                )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
    
    private func formatHours(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        return "\(hours)h"
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let icon: String
    let title: String
    let value: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? color.opacity(0.2)
                            : Color(.systemGray5)
                    )
                    .frame(width: 56, height: 56)
                
                if isUnlocked {
                    Circle()
                        .strokeBorder(color.opacity(0.3), lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? color : .gray)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Course.self, Video.self, WatchSession.self, UserSettings.self], inMemory: true)
}
