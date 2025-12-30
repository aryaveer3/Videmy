//
//  SharedURLsImportSheet.swift
//  Video Progress Tracker
//
//  Sheet for importing URLs shared from other apps
//

import SwiftUI
import SwiftData

struct SharedURLsImportSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let urls: [SharedURLData]
    let onComplete: () -> Void
    
    @State private var importStates: [UUID: ImportState] = [:]
    @State private var isImporting = false
    
    enum ImportState {
        case pending
        case importing
        case success
        case failed(String)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header info
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                            
                            Text("\(urls.count) item\(urls.count == 1 ? "" : "s") to import")
                                .font(.headline)
                            
                            Text("These were shared from other apps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical)
                        
                        // URL list
                        ForEach(Array(urls.enumerated()), id: \.element.url) { index, urlData in
                            SharedURLRow(
                                urlData: urlData,
                                state: importStates[UUID()] ?? .pending,
                                onRemove: {
                                    removeURL(at: index)
                                }
                            )
                        }
                        
                        // Import all button
                        if !urls.isEmpty {
                            Button {
                                importAllURLs()
                            } label: {
                                HStack {
                                    if isImporting {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 4)
                                    }
                                    Text(isImporting ? "Importing..." : "Import All")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isImporting ? Color.gray : Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isImporting)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        clearAndDismiss()
                    }
                }
            }
        }
    }
    
    private func removeURL(at index: Int) {
        SharedDataManager.shared.removeSharedURL(at: index)
    }
    
    private func importAllURLs() {
        isImporting = true
        
        Task {
            let courseManager = CourseManager(modelContext: modelContext)
            
            for urlData in urls {
                do {
                    _ = try await courseManager.createCourse(from: urlData.url, title: urlData.title)
                } catch {
                    print("Failed to import \(urlData.url): \(error)")
                }
            }
            
            await MainActor.run {
                isImporting = false
                SharedDataManager.shared.clearSharedURLs()
                onComplete()
                dismiss()
            }
        }
    }
    
    private func clearAndDismiss() {
        SharedDataManager.shared.clearSharedURLs()
        dismiss()
    }
}

// MARK: - Shared URL Row

struct SharedURLRow: View {
    let urlData: SharedURLData
    let state: SharedURLsImportSheet.ImportState
    let onRemove: () -> Void
    
    private var urlType: URLType {
        if urlData.url.contains("playlist") {
            return .playlist
        } else if urlData.url.contains("shorts") {
            return .shorts
        } else {
            return .video
        }
    }
    
    enum URLType {
        case video, playlist, shorts
        
        var icon: String {
            switch self {
            case .video: return "play.rectangle.fill"
            case .playlist: return "list.bullet.rectangle.fill"
            case .shorts: return "bolt.fill"
            }
        }
        
        var label: String {
            switch self {
            case .video: return "Video"
            case .playlist: return "Playlist"
            case .shorts: return "Short"
            }
        }
        
        var color: Color {
            switch self {
            case .video: return .red
            case .playlist: return .purple
            case .shorts: return .orange
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(urlType.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: urlType.icon)
                    .foregroundStyle(urlType.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(urlData.title ?? urlType.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(urlData.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("Shared \(urlData.addedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    SharedURLsImportSheet(
        urls: [
            SharedURLData(url: "https://youtube.com/watch?v=abc123", title: "SwiftUI Tutorial"),
            SharedURLData(url: "https://youtube.com/playlist?list=xyz456")
        ],
        onComplete: {}
    )
}
