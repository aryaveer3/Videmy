//
//  CourseDetailView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData

enum VideoSortOption: String, CaseIterable {
    case orderIndex = "Default Order"
    case unwatchedFirst = "Unwatched First"
    case duration = "Duration"
    case recentlyWatched = "Recently Watched"
}

struct CourseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: Course
    
    @State private var searchText = ""
    @State private var sortOption: VideoSortOption = .orderIndex
    @State private var showingAddVideo = false
    @State private var selectedVideo: Video?
    
    private var sortedVideos: [Video] {
        var videos = course.videos
        
        // Filter by search
        if !searchText.isEmpty {
            videos = videos.filter { video in
                video.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .orderIndex:
            return videos.sorted { $0.orderIndex < $1.orderIndex }
        case .unwatchedFirst:
            return videos.sorted { !$0.isCompleted && $1.isCompleted }
        case .duration:
            return videos.sorted { $0.duration < $1.duration }
        case .recentlyWatched:
            return videos.sorted { $0.lastWatchedDate > $1.lastWatchedDate }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header Section
                CourseHeaderView(course: course)
                    .padding(.horizontal)
                    .liquidAppear(delay: 0.1)
                
                // Continue Watching
                if let continueVideo = course.continueWatchingVideo {
                    VStack(alignment: .leading, spacing: 10) {
                        LiquidSectionHeader(title: "Continue Watching")
                            .padding(.horizontal)
                        
                        NavigationLink {
                            VideoPlayerView(video: continueVideo, course: course)
                        } label: {
                            ContinueVideoCard(video: continueVideo)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .liquidAppear(delay: 0.2)
                }
                
                LiquidDivider()
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                
                // Sort Options
                HStack {
                    Text("Videos (\(course.videos.count))")
                        .font(.headline)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(VideoSortOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.snappy) {
                                    sortOption = option
                                }
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                // Video List
                LiquidCard(style: .subtle) {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedVideos.enumerated()), id: \.element.id) { index, video in
                            NavigationLink {
                                VideoPlayerView(video: video, course: course)
                            } label: {
                                VideoRowView(video: video)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if video.isCompleted {
                                    Button {
                                        video.markIncomplete()
                                    } label: {
                                        Label("Mark as Incomplete", systemImage: "circle")
                                    }
                                } else {
                                    Button {
                                        video.markCompleted()
                                    } label: {
                                        Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                                    }
                                }
                                
                                Button {
                                    video.resetProgress()
                                } label: {
                                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    deleteVideo(video)
                                } label: {
                                    Label("Remove Video", systemImage: "trash")
                                }
                            }
                            
                            if index < sortedVideos.count - 1 {
                                LiquidDivider(opacity: 0.1)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .liquidBackground()
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search videos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingAddVideo = true
                    } label: {
                        Label("Add Video", systemImage: "plus")
                    }
                    
                    Button {
                        markAllCompleted()
                    } label: {
                        Label("Mark All Completed", systemImage: "checkmark.circle.fill")
                    }
                    
                    Button {
                        resetAllProgress()
                    } label: {
                        Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddVideo) {
            AddVideoSheet(course: course)
        }
    }
    
    private func deleteVideo(_ video: Video) {
        withAnimation {
            if let index = course.videos.firstIndex(where: { $0.id == video.id }) {
                course.videos.remove(at: index)
            }
            modelContext.delete(video)
            course.updateTotalDuration()
        }
    }
    
    private func markAllCompleted() {
        withAnimation {
            for video in course.videos {
                video.markCompleted()
            }
        }
    }
    
    private func resetAllProgress() {
        withAnimation {
            for video in course.videos {
                video.resetProgress()
            }
        }
    }
}

// MARK: - Course Header View

struct CourseHeaderView: View {
    let course: Course
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Thumbnail with glass overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15), radius: 16, x: 0, y: 8)
            }
            
            // Progress Section
            LiquidCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Course Progress")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(course.completedPercentage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(progressColor)
                    }
                    
                    LiquidProgressBar(
                        progress: course.completedPercentage / 100,
                        tint: progressColor,
                        height: 10
                    )
                    
                    HStack {
                        Label("\(course.completedVideosCount)/\(course.videos.count) videos", systemImage: "play.rectangle")
                        
                        Spacer()
                        
                        Label(formattedDuration, systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var progressColor: Color {
        if course.completedPercentage >= 100 {
            return .green
        } else if course.completedPercentage > 0 {
            return .blue
        }
        return .gray
    }
    
    private var formattedDuration: String {
        let hours = Int(course.totalDuration) / 3600
        let minutes = (Int(course.totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Continue Video Card

struct ContinueVideoCard: View {
    let video: Video
    
    var body: some View {
        LiquidCard(style: .highlighted) {
            HStack(spacing: 14) {
                ZStack {
                    LiquidThumbnail(
                        url: video.thumbnailURL,
                        size: CGSize(width: 140, height: 79),
                        cornerRadius: 10
                    )
                    
                    // Play overlay
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    LiquidProgressBar(progress: video.progressPercentage / 100, height: 6)
                    
                    Text("\(video.formattedWatchedDuration) / \(video.formattedDuration)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Video Row View

struct VideoRowView: View {
    let video: Video
    
    var body: some View {
        HStack(spacing: 14) {
            // Completion indicator
            ZStack {
                if video.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                } else if video.watchedDuration > 0 {
                    LiquidCircularProgress(
                        progress: video.progressPercentage / 100,
                        size: 28
                    )
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .frame(width: 32)
            
            // Thumbnail
            LiquidThumbnail(
                url: video.thumbnailURL,
                size: CGSize(width: 80, height: 45),
                cornerRadius: 8
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(video.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Circular Progress View (Legacy - use LiquidCircularProgress instead)

struct CircularProgressView: View {
    let progress: Double
    
    // Safe progress value clamped between 0 and 1, guards against NaN
    private var safeProgress: Double {
        guard !progress.isNaN && !progress.isInfinite else { return 0 }
        return max(0, min(1, progress))
    }
    
    var body: some View {
        LiquidCircularProgress(progress: safeProgress)
    }
}

// MARK: - Add Video Sheet

struct AddVideoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    
    @State private var videoURL = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("YouTube Video URL", text: $videoURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                } header: {
                    Text("Video URL")
                } footer: {
                    Text("Paste a YouTube video URL to add it to this course")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addVideo()
                        }
                    }
                    .disabled(videoURL.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func addVideo() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let courseManager = CourseManager(modelContext: modelContext)
        
        do {
            try await courseManager.addVideo(to: course, urlString: videoURL)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: Course(title: "Sample Course"))
    }
    .modelContainer(for: [Course.self, Video.self, WatchSession.self], inMemory: true)
}
