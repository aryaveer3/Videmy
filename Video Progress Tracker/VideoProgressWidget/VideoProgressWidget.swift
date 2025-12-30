//
//  VideoProgressWidget.swift
//  VideoProgressWidget
//
//  Home Screen Widget showing learning streak and progress
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), data: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = WidgetEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = WidgetEntry(date: Date(), data: data)
        
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Streak
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(data.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("\(data.completedVideos)/\(data.totalVideos)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ProgressView(value: data.overallProgress)
                    .tint(.blue)
                
                Text("videos completed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 12) {
                // Streak
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(data.currentStreak) days")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Current streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Watch time
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(data.formattedWatchTime)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Total watched")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Right side - Progress
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Courses")
                            .font(.caption)
                        Spacer()
                        Text("\(data.completedCourses)/\(data.totalCourses)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: data.totalCourses > 0 ? Double(data.completedCourses) / Double(data.totalCourses) : 0)
                        .tint(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Videos")
                            .font(.caption)
                        Spacer()
                        Text("\(data.completedVideos)/\(data.totalVideos)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: data.overallProgress)
                        .tint(.blue)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with streak
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(data.currentStreak) day streak")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Best: \(data.longestStreak) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text(data.formattedWatchTime)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("watched")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Overall Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(data.overallProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                ProgressView(value: data.overallProgress)
                    .tint(.blue)
                
                Text("\(data.completedVideos) of \(data.totalVideos) videos • \(data.completedCourses) of \(data.totalCourses) courses")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Recent Courses
            if !data.recentCourses.isEmpty {
                Divider()
                
                Text("Recent Courses")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(data.recentCourses.prefix(3)) { course in
                        HStack(spacing: 10) {
                            // Progress circle
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 28, height: 28)
                                
                                Circle()
                                    .trim(from: 0, to: course.progress)
                                    .stroke(progressColor(for: course.progress), lineWidth: 3)
                                    .frame(width: 28, height: 28)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(Int(course.progress * 100))")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text("\(course.videosCompleted)/\(course.totalVideos) videos")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func progressColor(for progress: Double) -> Color {
        if progress >= 1.0 {
            return .green
        } else if progress > 0.5 {
            return .blue
        } else if progress > 0 {
            return .orange
        }
        return .gray
    }
}

// MARK: - Widget Entry View

struct VideoProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget Configuration

struct VideoProgressWidget: Widget {
    let kind: String = "VideoProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VideoProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Learning Progress")
        .description("Track your learning streak and video progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    VideoProgressWidget()
} timeline: {
    WidgetEntry(date: .now, data: WidgetData(
        currentStreak: 7,
        longestStreak: 14,
        totalWatchTime: 12600,
        totalCourses: 5,
        completedCourses: 2,
        totalVideos: 45,
        completedVideos: 23,
        lastUpdated: Date(),
        recentCourses: []
    ))
}

#Preview(as: .systemMedium) {
    VideoProgressWidget()
} timeline: {
    WidgetEntry(date: .now, data: WidgetData(
        currentStreak: 7,
        longestStreak: 14,
        totalWatchTime: 12600,
        totalCourses: 5,
        completedCourses: 2,
        totalVideos: 45,
        completedVideos: 23,
        lastUpdated: Date(),
        recentCourses: []
    ))
}

#Preview(as: .systemLarge) {
    VideoProgressWidget()
} timeline: {
    WidgetEntry(date: .now, data: WidgetData(
        currentStreak: 7,
        longestStreak: 14,
        totalWatchTime: 12600,
        totalCourses: 5,
        completedCourses: 2,
        totalVideos: 45,
        completedVideos: 23,
        lastUpdated: Date(),
        recentCourses: [
            WidgetCourseData(id: UUID(), title: "SwiftUI Masterclass", thumbnailURL: "", progress: 0.75, videosCompleted: 15, totalVideos: 20),
            WidgetCourseData(id: UUID(), title: "iOS Development", thumbnailURL: "", progress: 0.4, videosCompleted: 8, totalVideos: 20),
            WidgetCourseData(id: UUID(), title: "Machine Learning Basics", thumbnailURL: "", progress: 0.1, videosCompleted: 1, totalVideos: 10)
        ]
    ))
}
