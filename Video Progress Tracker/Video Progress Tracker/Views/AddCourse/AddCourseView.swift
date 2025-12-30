//
//  AddCourseView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData

enum AddCourseOption: String, CaseIterable {
    case playlist = "YouTube Playlist"
    case video = "Single Video"
    case manual = "Manual Creation"
    
    var icon: String {
        switch self {
        case .playlist: return "list.bullet.rectangle"
        case .video: return "play.rectangle"
        case .manual: return "square.and.pencil"
        }
    }
    
    var description: String {
        switch self {
        case .playlist: return "Import all videos from a YouTube playlist"
        case .video: return "Add a single YouTube video as a course"
        case .manual: return "Create a course and add videos one by one"
        }
    }
}

struct AddCourseView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOption: AddCourseOption?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid background
                LiquidBackground()
                
                VStack(spacing: 24) {
                    Text("How would you like to create your course?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        ForEach(AddCourseOption.allCases, id: \.self) { option in
                            Button {
                                selectedOption = option
                            } label: {
                                OptionCard(option: option)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedOption) { option in
                switch option {
                case .playlist:
                    ImportPlaylistView()
                case .video:
                    ImportVideoView()
                case .manual:
                    ManualCourseView()
                }
            }
        }
    }
}

// MARK: - Option Card

struct OptionCard: View {
    let option: AddCourseOption
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(option.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(option.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Import Playlist View

struct ImportPlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistURL = ""
    @State private var courseTitle = ""
    @State private var isLoading = false
    @State private var importProgress: Double = 0
    @State private var errorMessage: String?
    @State private var importedCourse: Course?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("YouTube Playlist URL", text: $playlistURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                } header: {
                    Text("Playlist URL")
                } footer: {
                    Text("Paste the full URL of a YouTube playlist")
                }
                
                Section {
                    TextField("Course Title (Optional)", text: $courseTitle)
                } header: {
                    Text("Course Title")
                } footer: {
                    Text("Leave empty to use the playlist name")
                }
                
                if isLoading {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: importProgress)
                                .tint(.blue)
                            
                            Text("Importing videos... \(Int(importProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                if let course = importedCourse {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Import Successful!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            Text("\(course.videos.count) videos imported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Import Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if importedCourse != nil {
                        Button("Done") {
                            dismiss()
                        }
                    } else {
                        Button("Import") {
                            Task {
                                await importPlaylist()
                            }
                        }
                        .disabled(playlistURL.isEmpty || isLoading)
                    }
                }
            }
        }
    }
    
    private func importPlaylist() async {
        isLoading = true
        errorMessage = nil
        importedCourse = nil
        
        let courseManager = CourseManager(modelContext: modelContext)
        
        // Observe progress
        let observation = courseManager.$importProgress.sink { progress in
            Task { @MainActor in
                self.importProgress = progress
            }
        }
        
        do {
            let course = try await courseManager.createCourse(
                from: playlistURL,
                title: courseTitle.isEmpty ? nil : courseTitle
            )
            importedCourse = course
        } catch {
            errorMessage = error.localizedDescription
        }
        
        observation.cancel()
        isLoading = false
    }
}

// MARK: - Import Video View

struct ImportVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var videoURL = ""
    @State private var courseTitle = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var importedCourse: Course?
    
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
                    Text("Paste the URL of a YouTube video")
                }
                
                Section {
                    TextField("Course Title (Optional)", text: $courseTitle)
                } header: {
                    Text("Course Title")
                } footer: {
                    Text("Leave empty to use the video title")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                if importedCourse != nil {
                    Section {
                        Label("Video Added!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
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
                    if importedCourse != nil {
                        Button("Done") {
                            dismiss()
                        }
                    } else {
                        Button("Add") {
                            Task {
                                await importVideo()
                            }
                        }
                        .disabled(videoURL.isEmpty || isLoading)
                    }
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
    
    private func importVideo() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let courseManager = CourseManager(modelContext: modelContext)
        
        do {
            let course = try await courseManager.createCourse(
                from: videoURL,
                title: courseTitle.isEmpty ? nil : courseTitle
            )
            importedCourse = course
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Manual Course View

struct ManualCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var courseTitle = ""
    @State private var videoURLs: [String] = [""]
    @State private var isLoading = false
    @State private var importProgress: Double = 0
    @State private var errorMessage: String?
    @State private var importedCourse: Course?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Course Title", text: $courseTitle)
                } header: {
                    Text("Course Title")
                }
                
                Section {
                    ForEach(videoURLs.indices, id: \.self) { index in
                        HStack {
                            TextField("Video URL \(index + 1)", text: $videoURLs[index])
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                            
                            if videoURLs.count > 1 {
                                Button {
                                    videoURLs.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    
                    Button {
                        videoURLs.append("")
                    } label: {
                        Label("Add Another Video", systemImage: "plus")
                    }
                } header: {
                    Text("Videos")
                } footer: {
                    Text("Add YouTube video URLs to your course")
                }
                
                if isLoading {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: importProgress)
                                .tint(.blue)
                            
                            Text("Adding videos... \(Int(importProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                if let course = importedCourse {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Course Created!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            Text("\(course.videos.count) videos added")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if importedCourse != nil {
                        Button("Done") {
                            dismiss()
                        }
                    } else {
                        Button("Create") {
                            Task {
                                await createCourse()
                            }
                        }
                        .disabled(courseTitle.isEmpty || validURLs.isEmpty || isLoading)
                    }
                }
            }
        }
    }
    
    private var validURLs: [String] {
        videoURLs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    private func createCourse() async {
        isLoading = true
        errorMessage = nil
        importedCourse = nil
        
        let courseManager = CourseManager(modelContext: modelContext)
        
        // Observe progress
        let observation = courseManager.$importProgress.sink { progress in
            Task { @MainActor in
                self.importProgress = progress
            }
        }
        
        do {
            let course = try await courseManager.createManualCourse(
                title: courseTitle,
                videoURLs: validURLs
            )
            importedCourse = course
        } catch {
            errorMessage = error.localizedDescription
        }
        
        observation.cancel()
        isLoading = false
    }
}

// MARK: - Identifiable Conformance

extension AddCourseOption: Identifiable {
    var id: String { rawValue }
}

#Preview {
    AddCourseView()
        .modelContainer(for: [Course.self, Video.self], inMemory: true)
}
