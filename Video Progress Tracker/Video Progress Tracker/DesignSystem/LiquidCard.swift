//
//  LiquidCard.swift
//  Video Progress Tracker
//
//  iOS 26 Liquid UI - Glassmorphic Card Component
//

import SwiftUI

/// A floating, glassy card with translucent material background
struct LiquidCard<Content: View>: View {
    let content: Content
    var style: CardStyle = .standard
    var isSelected: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum CardStyle {
        case standard       // Regular card
        case elevated       // More prominent card
        case subtle         // Less prominent, inline card
        case highlighted    // Currently active/selected
    }
    
    init(
        style: CardStyle = .standard,
        isSelected: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.isSelected = isSelected
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(cardPadding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: borderWidth)
            )
    }
    
    // MARK: - Style Properties
    
    private var cardPadding: CGFloat {
        switch style {
        case .standard: return 16
        case .elevated: return 20
        case .subtle: return 12
        case .highlighted: return 16
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return 20
        case .elevated: return 24
        case .subtle: return 16
        case .highlighted: return 20
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .standard:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.thinMaterial)
        case .subtle:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.7))
        case .highlighted:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                )
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark 
            ? Color.black.opacity(0.4)
            : Color.black.opacity(0.08)
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .standard: return 12
        case .elevated: return 20
        case .subtle: return 6
        case .highlighted: return 16
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .standard: return 6
        case .elevated: return 8
        case .subtle: return 3
        case .highlighted: return 6
        }
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 0.5
    }
}

// MARK: - Convenience Modifiers

extension View {
    func liquidCard(style: LiquidCard<Self>.CardStyle = .standard, isSelected: Bool = false) -> some View {
        LiquidCard(style: style, isSelected: isSelected) {
            self
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LiquidCard(style: .standard) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard Card")
                    .font(.headline)
                Text("This is a standard liquid card")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        LiquidCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Elevated Card")
                    .font(.headline)
                Text("This card has more prominence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        LiquidCard(style: .highlighted) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Highlighted Card")
                    .font(.headline)
                Text("Currently selected or active")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .liquidBackground()
}
