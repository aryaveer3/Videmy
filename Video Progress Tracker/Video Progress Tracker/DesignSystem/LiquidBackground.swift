//
//  LiquidBackground.swift
//  Video Progress Tracker
//
//  iOS 26 Liquid UI - Glassmorphic Background Component
//

import SwiftUI

/// A layered, translucent background with subtle gradient orbs for depth
struct LiquidBackground: View {
    var style: BackgroundStyle = .primary
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    enum BackgroundStyle {
        case primary    // Main screens
        case secondary  // Sheets/modals
        case player     // Video player background
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(1, geometry.size.width)
            let safeHeight = max(1, geometry.size.height)
            
            ZStack {
                // Base gradient
                baseGradient
                
                // Floating orbs for depth (subtle)
                if !reduceMotion && safeWidth > 1 && safeHeight > 1 {
                    floatingOrbs(width: safeWidth, height: safeHeight)
                }
                
                // Material overlay for glass effect
                materialOverlay
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var baseGradient: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color(.systemBackground), Color(.systemBackground).opacity(0.95)]
                    : [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color(.secondarySystemBackground)
        case .player:
            Color.black
        }
    }
    
    @ViewBuilder
    private func floatingOrbs(width: CGFloat, height: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.blue.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.4
                )
            )
            .frame(width: width * 0.8, height: width * 0.8)
            .offset(x: -width * 0.3, y: -height * 0.2)
            .blur(radius: 60)
        
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.purple.opacity(0.1), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.3
                )
            )
            .frame(width: width * 0.6, height: width * 0.6)
            .offset(x: width * 0.3, y: height * 0.3)
            .blur(radius: 50)
    }
    
    @ViewBuilder
    private var materialOverlay: some View {
        switch style {
        case .primary, .secondary:
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
        case .player:
            EmptyView()
        }
    }
}

// MARK: - View Extension for Easy Application

extension View {
    func liquidBackground(_ style: LiquidBackground.BackgroundStyle = .primary) -> some View {
        self.background(LiquidBackground(style: style))
    }
}

#Preview {
    VStack {
        Text("Liquid Background")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .liquidBackground()
}
