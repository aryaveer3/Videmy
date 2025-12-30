//
//  ShareViewController.swift
//  AddToLearning
//
//  Share Extension for adding YouTube videos/playlists to Video Progress Tracker
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract URL from share content
        extractSharedURL { [weak self] url, title in
            DispatchQueue.main.async {
                if let url = url {
                    self?.showShareUI(url: url, title: title)
                } else {
                    self?.showError("No valid YouTube URL found")
                }
            }
        }
    }
    
    private func extractSharedURL(completion: @escaping (String?, String?) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completion(nil, nil)
            return
        }
        
        // Try to get URL
        for attachment in attachments {
            // Check for URL type
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                    if let url = data as? URL {
                        let urlString = url.absoluteString
                        if self.isValidYouTubeURL(urlString) {
                            completion(urlString, nil)
                            return
                        }
                    }
                    completion(nil, nil)
                }
                return
            }
            
            // Check for plain text (might contain URL)
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
                    if let text = data as? String {
                        // Extract YouTube URL from text
                        if let url = self.extractYouTubeURL(from: text) {
                            completion(url, nil)
                            return
                        }
                    }
                    completion(nil, nil)
                }
                return
            }
        }
        
        completion(nil, nil)
    }
    
    private func isValidYouTubeURL(_ urlString: String) -> Bool {
        let patterns = [
            "youtube.com/watch",
            "youtube.com/playlist",
            "youtu.be/",
            "youtube.com/shorts"
        ]
        return patterns.contains { urlString.contains($0) }
    }
    
    private func extractYouTubeURL(from text: String) -> String? {
        // Regex to find YouTube URLs
        let patterns = [
            "https?://(?:www\\.)?youtube\\.com/watch\\?[^\\s]+",
            "https?://(?:www\\.)?youtube\\.com/playlist\\?[^\\s]+",
            "https?://youtu\\.be/[^\\s]+",
            "https?://(?:www\\.)?youtube\\.com/shorts/[^\\s]+"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let swiftRange = Range(match.range, in: text) {
                        return String(text[swiftRange])
                    }
                }
            }
        }
        
        return nil
    }
    
    private func showShareUI(url: String, title: String?) {
        let shareView = ShareExtensionView(
            url: url,
            detectedTitle: title,
            onSave: { [weak self] savedURL, savedTitle in
                self?.saveAndClose(url: savedURL, title: savedTitle)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancel()
        })
        present(alert, animated: true)
    }
    
    private func saveAndClose(url: String, title: String?) {
        // Save to shared UserDefaults
        let sharedData = SharedURLData(url: url, title: title)
        SharedDataManager.shared.addSharedURL(sharedData)
        
        // Close extension
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "com.videoprogress.share", code: 0, userInfo: nil))
    }
}

// MARK: - Share Extension SwiftUI View

struct ShareExtensionView: View {
    let url: String
    let detectedTitle: String?
    let onSave: (String, String?) -> Void
    let onCancel: () -> Void
    
    @State private var customTitle: String = ""
    @State private var urlType: URLType = .unknown
    
    enum URLType {
        case video
        case playlist
        case shorts
        case unknown
        
        var icon: String {
            switch self {
            case .video: return "play.rectangle.fill"
            case .playlist: return "list.bullet.rectangle.fill"
            case .shorts: return "bolt.fill"
            case .unknown: return "link"
            }
        }
        
        var label: String {
            switch self {
            case .video: return "YouTube Video"
            case .playlist: return "YouTube Playlist"
            case .shorts: return "YouTube Short"
            case .unknown: return "YouTube Content"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Header
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundStyle(.blue)
                
                Spacer()
                
                Text("Add to Learning")
                    .font(.headline)
                
                Spacer()
                
                Button("Add") {
                    onSave(url, customTitle.isEmpty ? nil : customTitle)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Content
            VStack(spacing: 16) {
                // URL Type indicator
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: urlType.icon)
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(urlType.label)
                            .font(.headline)
                        
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Custom title (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Title (Optional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter a title...", text: $customTitle)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Text("Open Video Progress Tracker to import this content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .onAppear {
            detectURLType()
        }
    }
    
    private func detectURLType() {
        if url.contains("playlist") {
            urlType = .playlist
        } else if url.contains("shorts") {
            urlType = .shorts
        } else if url.contains("watch") || url.contains("youtu.be") {
            urlType = .video
        } else {
            urlType = .unknown
        }
    }
}

// Note: SharedDataManager needs to be accessible here.
// Copy the SharedDataManager.swift file to this target or use a shared framework.
