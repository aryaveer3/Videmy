//
//  ContentView.swift
//  Video Progress Tracker
//
//  Created by Bajpai, Aryaveer on 26/12/25.
//

import SwiftUI
import SwiftData

// MARK: - Tab Identifiers

enum AppTab: String, CaseIterable, Identifiable {
    case courses
    case analytics
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .courses: return "Courses"
        case .analytics: return "Analytics"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .courses: return "book.fill"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .courses
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.courses.title, systemImage: AppTab.courses.icon, value: .courses) {
                HomeView()
            }
            
            Tab(AppTab.analytics.title, systemImage: AppTab.analytics.icon, value: .analytics) {
                AnalyticsView()
            }
            
            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @Query private var settings: [UserSettings]
    
    @State private var showingResetAlert = false
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Info Card
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "play.rectangle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Video Progress Tracker")
                                    .font(.headline)
                                Text("Track your learning journey")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                        
                        // Stats Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Statistics")
                                .font(.headline)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "book.fill",
                                    iconColor: .blue,
                                    title: "Total Courses",
                                    value: "\(courses.count)"
                                )
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsRow(
                                    icon: "play.rectangle.fill",
                                    iconColor: .purple,
                                    title: "Videos",
                                    value: "\(courses.flatMap { $0.videos }.count)"
                                )
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsRow(
                                    icon: "clock.fill",
                                    iconColor: .orange,
                                    title: "Watch Time",
                                    value: userSettings?.formattedTotalWatchTime ?? "0m"
                                )
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsRow(
                                    icon: "flame.fill",
                                    iconColor: .red,
                                    title: "Current Streak",
                                    value: "\(userSettings?.currentStreak ?? 0) days"
                                )
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsRow(
                                    icon: "trophy.fill",
                                    iconColor: .yellow,
                                    title: "Best Streak",
                                    value: "\(userSettings?.longestStreak ?? 0) days"
                                )
                            }
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        }
                        
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Management")
                                .font(.headline)
                                .padding(.horizontal, 4)
                            
                            Button {
                                showingResetAlert = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "arrow.counterclockwise")
                                            .foregroundStyle(.red)
                                    }
                                    
                                    Text("Reset All Progress")
                                        .foregroundStyle(.red)
                                    
                                    Spacer()
                                }
                                .padding(12)
                            }
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Version")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(16)
                                
                                Divider().padding(.leading, 16)
                                
                                Link(destination: URL(string: "https://www.youtube.com")!) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "play.rectangle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        
                                        Text("YouTube")
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(12)
                                }
                            }
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Progress?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllProgress()
                }
            } message: {
                Text("This will reset all watch progress for all courses. This action cannot be undone.")
            }
        }
    }
    
    private func resetAllProgress() {
        for course in courses {
            for video in course.videos {
                video.resetProgress()
            }
        }
        
        if let settings = userSettings {
            settings.totalWatchTime = 0
            settings.currentStreak = 0
            settings.lastWatchDate = nil
        }
        
        try? modelContext.save()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            Text(title)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Legacy ContentView (kept for compatibility)

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Course.self, Video.self, WatchSession.self, UserSettings.self], inMemory: true)
}
