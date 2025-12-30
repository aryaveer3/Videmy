//
//  Video_Progress_TrackerApp.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct Video_Progress_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Course.self,
            Video.self,
            WatchSession.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Check for shared URLs from Share Extension
                    checkForSharedURLs()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    checkForSharedURLs()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func checkForSharedURLs() {
        let sharedURLs = SharedDataManager.shared.loadSharedURLs()
        if !sharedURLs.isEmpty {
            // Post notification to show import sheet
            NotificationCenter.default.post(name: .sharedURLsAvailable, object: sharedURLs)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sharedURLsAvailable = Notification.Name("sharedURLsAvailable")
    static let widgetDataNeedsUpdate = Notification.Name("widgetDataNeedsUpdate")
}

// MARK: - Widget Update Helper

extension View {
    func updateWidgetOnChange() -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .widgetDataNeedsUpdate)) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
