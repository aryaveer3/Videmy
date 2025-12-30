//
//  YouTubeService.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import Foundation

// MARK: - YouTube URL Parser

enum YouTubeURLType {
    case video(id: String)
    case playlist(id: String, videoIds: [String]?)
    case invalid
}

struct YouTubeService {
    
    // MARK: - Custom URLSession that bypasses SSL for corporate networks
    
    private static var bypassSSLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration, delegate: SSLBypassDelegate(), delegateQueue: nil)
    }()
    
    // MARK: - URL Parsing
    
    /// Parse a YouTube URL and extract video or playlist ID
    static func parseURL(_ urlString: String) -> YouTubeURLType {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: trimmedURL) else {
            // Try to extract video ID directly (might be just the ID)
            if trimmedURL.count == 11 && !trimmedURL.contains("/") {
                return .video(id: trimmedURL)
            }
            return .invalid
        }
        
        // Check for playlist - also extract video IDs if present in URL
        if let playlistId = extractPlaylistId(from: url) {
            // Also extract any video IDs from the URL itself
            let videoId = extractVideoId(from: url)
            return .playlist(id: playlistId, videoIds: videoId != nil ? [videoId!] : nil)
        }
        
        // Check for video
        if let videoId = extractVideoId(from: url) {
            return .video(id: videoId)
        }
        
        return .invalid
    }
    
    /// Extract video ID from various YouTube URL formats
    static func extractVideoId(from url: URL) -> String? {
        let urlString = url.absoluteString
        
        // Standard watch URL: youtube.com/watch?v=VIDEO_ID
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return videoId.prefix(11).description // Ensure 11 chars
        }
        
        // Short URL: youtu.be/VIDEO_ID
        if url.host == "youtu.be" || url.host == "www.youtu.be" {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.count >= 11 {
                return String(path.prefix(11))
            }
        }
        
        // Embed URL: youtube.com/embed/VIDEO_ID
        if urlString.contains("/embed/") {
            let components = url.pathComponents
            if let embedIndex = components.firstIndex(of: "embed"),
               embedIndex + 1 < components.count {
                let id = components[embedIndex + 1]
                return id.count >= 11 ? String(id.prefix(11)) : nil
            }
        }
        
        // Shorts URL: youtube.com/shorts/VIDEO_ID
        if urlString.contains("/shorts/") {
            let components = url.pathComponents
            if let shortsIndex = components.firstIndex(of: "shorts"),
               shortsIndex + 1 < components.count {
                let id = components[shortsIndex + 1]
                return id.count >= 11 ? String(id.prefix(11)) : nil
            }
        }
        
        // Live URL: youtube.com/live/VIDEO_ID
        if urlString.contains("/live/") {
            let components = url.pathComponents
            if let liveIndex = components.firstIndex(of: "live"),
               liveIndex + 1 < components.count {
                let id = components[liveIndex + 1]
                return id.count >= 11 ? String(id.prefix(11)) : nil
            }
        }
        
        return nil
    }
    
    /// Extract playlist ID from URL
    static func extractPlaylistId(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return queryItems.first(where: { $0.name == "list" })?.value
    }
    
    // MARK: - Metadata Fetching
    
    /// Fetch video metadata - tries multiple methods
    static func fetchVideoMetadata(videoId: String) async throws -> VideoMetadata {
        // Try oEmbed first
        if let metadata = try? await fetchVideoMetadataOEmbed(videoId: videoId) {
            return metadata
        }
        
        // Try noembed as fallback
        if let metadata = try? await fetchVideoInfo(videoId: videoId) {
            return metadata
        }
        
        // Return basic metadata with just thumbnail
        return VideoMetadata(
            id: videoId,
            title: "Video \(videoId)",
            thumbnailURL: thumbnailURL(for: videoId),
            duration: 0
        )
    }
    
    /// Fetch video metadata using oEmbed API (no API key required)
    private static func fetchVideoMetadataOEmbed(videoId: String) async throws -> VideoMetadata {
        let urlString = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        // Try with bypass session first, then regular
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(from: url)
        } catch {
            (data, _) = try await URLSession.shared.data(from: url)
        }
        
        let decoder = JSONDecoder()
        let oEmbedResponse = try decoder.decode(OEmbedResponse.self, from: data)
        
        return VideoMetadata(
            id: videoId,
            title: oEmbedResponse.title,
            thumbnailURL: oEmbedResponse.thumbnail_url,
            duration: 0
        )
    }
    
    /// Fetch video info using noembed.com (alternative no-key API)
    static func fetchVideoInfo(videoId: String) async throws -> VideoMetadata {
        let urlString = "https://noembed.com/embed?url=https://www.youtube.com/watch?v=\(videoId)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(from: url)
        } catch {
            (data, _) = try await URLSession.shared.data(from: url)
        }
        
        let decoder = JSONDecoder()
        let noEmbedResponse = try decoder.decode(NoEmbedResponse.self, from: data)
        
        return VideoMetadata(
            id: videoId,
            title: noEmbedResponse.title ?? "Video \(videoId)",
            thumbnailURL: noEmbedResponse.thumbnail_url ?? thumbnailURL(for: videoId),
            duration: 0
        )
    }
    
    /// Generate thumbnail URL for a video
    static func thumbnailURL(for videoId: String, quality: ThumbnailQuality = .medium) -> String {
        switch quality {
        case .default:
            return "https://img.youtube.com/vi/\(videoId)/default.jpg"
        case .medium:
            return "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg"
        case .high:
            return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        case .maxRes:
            return "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg"
        }
    }
}

// MARK: - SSL Bypass Delegate for Corporate Networks

class SSLBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept any certificate (needed for corporate proxy/Zscaler)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Supporting Types

struct VideoMetadata {
    let id: String
    let title: String
    let thumbnailURL: String
    let duration: Double
}

struct OEmbedResponse: Codable {
    let title: String
    let author_name: String?
    let thumbnail_url: String
    let thumbnail_width: Int?
    let thumbnail_height: Int?
}

struct NoEmbedResponse: Codable {
    let title: String?
    let author_name: String?
    let thumbnail_url: String?
    let provider_name: String?
}

enum ThumbnailQuality {
    case `default`
    case medium
    case high
    case maxRes
}

enum YouTubeError: Error, LocalizedError {
    case invalidURL
    case fetchFailed
    case parsingFailed
    case playlistFetchFailed
    case noVideosFound
    case sslError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid YouTube URL"
        case .fetchFailed:
            return "Failed to fetch video information"
        case .parsingFailed:
            return "Failed to parse response"
        case .playlistFetchFailed:
            return "Failed to fetch playlist. Try adding videos individually."
        case .noVideosFound:
            return "No videos found"
        case .sslError:
            return "Network security error. Try using a different network."
        }
    }
}

// MARK: - Playlist Extraction

extension YouTubeService {
    
    /// Try to extract video IDs from a playlist page using multiple methods
    static func extractPlaylistVideoIds(playlistId: String) async throws -> [String] {
        // Method 1: Try web scraping with initial data JSON (gets ALL videos)
        if let videoIds = try? await extractFromInitialData(playlistId: playlistId), !videoIds.isEmpty {
            return videoIds
        }
        
        // Method 2: Try web scraping from HTML
        if let videoIds = try? await extractFromWebPage(playlistId: playlistId), !videoIds.isEmpty {
            return videoIds
        }
        
        // Method 3: Try RSS feed (limited to 15 videos but reliable)
        if let videoIds = try? await extractFromRSSFeed(playlistId: playlistId), !videoIds.isEmpty {
            return videoIds
        }
        
        // Method 4: Try alternate endpoint
        if let videoIds = try? await extractFromAlternateEndpoint(playlistId: playlistId), !videoIds.isEmpty {
            return videoIds
        }
        
        throw YouTubeError.playlistFetchFailed
    }
    
    /// Extract ALL videos from YouTube's initial data JSON (best method)
    private static func extractFromInitialData(playlistId: String) async throws -> [String] {
        let urlString = "https://www.youtube.com/playlist?list=\(playlistId)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(for: request)
        } catch {
            (data, _) = try await URLSession.shared.data(for: request)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw YouTubeError.parsingFailed
        }
        
        // Extract ytInitialData JSON which contains ALL playlist videos
        var videoIds: [String] = []
        
        // Look for ytInitialData
        if let startRange = html.range(of: "var ytInitialData = "),
           let endRange = html.range(of: ";</script>", range: startRange.upperBound..<html.endIndex) {
            let jsonString = String(html[startRange.upperBound..<endRange.lowerBound])
            
            // Parse video IDs from the JSON using regex (more reliable than JSON parsing)
            // Pattern matches: "videoId":"XXXXXXXXXXX" in playlistVideoRenderer
            let pattern = #""playlistVideoRenderer"\s*:\s*\{[^}]*"videoId"\s*:\s*"([a-zA-Z0-9_-]{11})""#
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                let range = NSRange(jsonString.startIndex..., in: jsonString)
                let matches = regex.matches(in: jsonString, options: [], range: range)
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: jsonString) {
                        let videoId = String(jsonString[range])
                        if !videoIds.contains(videoId) {
                            videoIds.append(videoId)
                        }
                    }
                }
            }
            
            // If first pattern didn't work, try simpler pattern
            if videoIds.isEmpty {
                let simplePattern = #""videoId"\s*:\s*"([a-zA-Z0-9_-]{11})""#
                if let regex = try? NSRegularExpression(pattern: simplePattern, options: []) {
                    let range = NSRange(jsonString.startIndex..., in: jsonString)
                    let matches = regex.matches(in: jsonString, options: [], range: range)
                    
                    var seen = Set<String>()
                    for match in matches {
                        if let range = Range(match.range(at: 1), in: jsonString) {
                            let videoId = String(jsonString[range])
                            // Filter out playlist/channel IDs
                            if !videoId.hasPrefix("PL") && !videoId.hasPrefix("UU") && !videoId.hasPrefix("RD") {
                                if !seen.contains(videoId) {
                                    seen.insert(videoId)
                                    videoIds.append(videoId)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return videoIds
    }
    
    /// Extract from YouTube RSS feed (limited to 15 most recent videos)
    private static func extractFromRSSFeed(playlistId: String) async throws -> [String] {
        let urlString = "https://www.youtube.com/feeds/videos.xml?playlist_id=\(playlistId)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(from: url)
        } catch {
            (data, _) = try await URLSession.shared.data(from: url)
        }
        
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw YouTubeError.parsingFailed
        }
        
        // Extract video IDs from RSS XML
        let pattern = #"<yt:videoId>([a-zA-Z0-9_-]{11})</yt:videoId>"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(xmlString.startIndex..., in: xmlString)
        let matches = regex.matches(in: xmlString, options: [], range: range)
        
        var videoIds: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: xmlString) {
                videoIds.append(String(xmlString[range]))
            }
        }
        
        return videoIds
    }
    
    /// Extract from web page with SSL bypass
    private static func extractFromWebPage(playlistId: String) async throws -> [String] {
        let urlString = "https://www.youtube.com/playlist?list=\(playlistId)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(for: request)
        } catch {
            (data, _) = try await URLSession.shared.data(for: request)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw YouTubeError.parsingFailed
        }
        
        // Multiple patterns to try - preserve order
        var videoIds: [String] = []
        var seen = Set<String>()
        
        let patterns = [
            #""videoId"\s*:\s*"([a-zA-Z0-9_-]{11})""#,
            #"watch\?v=([a-zA-Z0-9_-]{11})"#,
            #"/watch\?v=([a-zA-Z0-9_-]{11})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, options: [], range: range)
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: html) {
                        let videoId = String(html[range])
                        // Filter out common non-video IDs
                        if !videoId.hasPrefix("PL") && !videoId.hasPrefix("UU") && !videoId.hasPrefix("RD") {
                            if !seen.contains(videoId) {
                                seen.insert(videoId)
                                videoIds.append(videoId)
                            }
                        }
                    }
                }
            }
        }
        
        return videoIds
    }
    
    /// Try alternate endpoint
    private static func extractFromAlternateEndpoint(playlistId: String) async throws -> [String] {
        // Try the embed endpoint which sometimes works better
        let urlString = "https://www.youtube.com/embed/videoseries?list=\(playlistId)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let data: Data
        do {
            (data, _) = try await bypassSSLSession.data(for: request)
        } catch {
            (data, _) = try await URLSession.shared.data(for: request)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw YouTubeError.parsingFailed
        }
        
        let pattern = #""video_id"\s*:\s*"([a-zA-Z0-9_-]{11})""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw YouTubeError.parsingFailed
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        var videoIds = Set<String>()
        for match in matches {
            if let range = Range(match.range(at: 1), in: html) {
                videoIds.insert(String(html[range]))
            }
        }
        
        return Array(videoIds)
    }
}
