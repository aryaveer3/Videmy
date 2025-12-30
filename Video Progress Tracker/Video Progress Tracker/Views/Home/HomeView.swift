//
//  HomeView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.lastAccessedAt, order: .reverse) private var courses: [Course]
    @Query private var settings: [UserSettings]
    
    @State private var showingAddCourse = false
    @State private var showingSharedURLsSheet = false
    @State private var sharedURLs: [SharedURLData] = []
    @State private var searchText = ""
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        }
        return courses.filter { course in
            course.title.localizedCaseInsensitiveContains(searchText) ||
            course.videos.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var continueWatchingCourse: Course? {
        guard let lastCourseId = userSettings?.lastWatchedCourseId else { return nil }
        return courses.first { $0.id == lastCourseId }
    }
    
    private var inProgressCourses: [Course] {
        filteredCourses.filter { $0.completedPercentage > 0 && $0.completedPercentage < 100 }
    }
    
    private var notStartedCourses: [Course] {
        filteredCourses.filter { $0.completedPercentage == 0 }
    }
    
    private var completedCourses: [Course] {
        filteredCourses.filter { $0.completedPercentage >= 100 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    // Continue Watching Section
                    if let course = continueWatchingCourse,
                       let video = course.continueWatchingVideo {
                        ContinueWatchingCard(course: course, video: video)
                            .padding(.horizontal)
                            .liquidAppear(delay: 0.1)
                    }
                    
                    // In Progress Section
                    if !inProgressCourses.isEmpty {
                        CourseSection(
                            title: "In Progress",
                            courses: inProgressCourses,
                            onDelete: deleteCourse
                        )
                        .liquidAppear(delay: 0.2)
                    }
                    
                    // Not Started Section
                    if !notStartedCourses.isEmpty {
                        CourseSection(
                            title: "Not Started",
                            courses: notStartedCourses,
                            onDelete: deleteCourse
                        )
                        .liquidAppear(delay: 0.3)
                    }
                    
                    // Completed Section
                    if !completedCourses.isEmpty {
                        CourseSection(
                            title: "Completed",
                            courses: completedCourses,
                            onDelete: deleteCourse
                        )
                        .liquidAppear(delay: 0.4)
                    }
                    
                    // Empty State
                    if courses.isEmpty {
                        LiquidEmptyState(
                            icon: "books.vertical",
                            title: "No Courses Yet",
                            message: "Add a YouTube playlist or video to start learning"
                        )
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .liquidBackground()
            .navigationTitle("My Courses")
            .searchable(text: $searchText, prompt: "Search courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCourse = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView()
            }
            .sheet(isPresented: $showingSharedURLsSheet) {
                SharedURLsImportSheet(urls: sharedURLs) {
                    // Refresh widget after import
                    updateWidgetData()
                }
            }
            .onAppear {
                updateWidgetData()
                checkForSharedURLs()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sharedURLsAvailable)) { notification in
                if let urls = notification.object as? [SharedURLData] {
                    sharedURLs = urls
                    if !urls.isEmpty {
                        showingSharedURLsSheet = true
                    }
                }
            }
            .onChange(of: courses.count) { _, _ in
                updateWidgetData()
            }
        }
    }
    
    private func deleteCourse(_ course: Course) {
        withAnimation {
            modelContext.delete(course)
            updateWidgetData()
        }
    }
    
    private func updateWidgetData() {
        SharedDataManager.shared.updateWidgetData(courses: courses, settings: userSettings)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func checkForSharedURLs() {
        let urls = SharedDataManager.shared.loadSharedURLs()
        if !urls.isEmpty {
            sharedURLs = urls
            showingSharedURLsSheet = true
        }
    }
}

// MARK: - Continue Watching Card

struct ContinueWatchingCard: View {
    let course: Course
    let video: Video
    
    var body: some View {
        NavigationLink {
            VideoPlayerView(video: video, course: course)
        } label: {
            LiquidCard(style: .highlighted) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Continue Watching")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    HStack(spacing: 14) {
                        LiquidThumbnail(url: video.thumbnailURL, cornerRadius: 10)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(video.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .foregroundStyle(.primary)
                            
                            Text(course.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            let safeProgress = video.progressPercentage.isNaN ? 0 : max(0, min(100, video.progressPercentage))
                            LiquidProgressBar(progress: safeProgress / 100, height: 6)
                            
                            Text("\(video.formattedWatchedDuration) / \(video.formattedDuration)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course Section

struct CourseSection: View {
    let title: String
    let courses: [Course]
    let onDelete: (Course) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LiquidSectionHeader(title: title)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(courses) { course in
                        NavigationLink {
                            CourseDetailView(course: course)
                        } label: {
                            CourseCard(course: course)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete(course)
                            } label: {
                                Label("Delete Course", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Course Card

struct CourseCard: View {
    let course: Course
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail with glass overlay
            ZStack(alignment: .bottomTrailing) {
                LiquidThumbnail(
                    url: course.thumbnailURL,
                    size: CGSize(width: 200, height: 112),
                    cornerRadius: 14
                )
                
                let safePercentage = course.completedPercentage.isNaN ? 0 : course.completedPercentage
                if safePercentage > 0 {
                    Text("\(Int(safePercentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            
            // Title
            Text(course.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            // Progress
            let safeProgress = course.completedPercentage.isNaN ? 0 : max(0, min(100, course.completedPercentage))
            LiquidProgressBar(progress: safeProgress / 100, tint: progressColor, height: 6)
            
            // Stats
            HStack {
                Text("\(course.completedVideosCount)/\(course.videos.count) videos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var progressColor: Color {
        let safePercentage = course.completedPercentage.isNaN ? 0 : course.completedPercentage
        if safePercentage >= 100 {
            return .green
        } else if safePercentage > 0 {
            return .blue
        }
        return .gray
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        LiquidEmptyState(
            icon: "books.vertical",
            title: "No Courses Yet",
            message: "Add a YouTube playlist or video to start learning"
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Course.self, Video.self, WatchSession.self, UserSettings.self], inMemory: true)
}
