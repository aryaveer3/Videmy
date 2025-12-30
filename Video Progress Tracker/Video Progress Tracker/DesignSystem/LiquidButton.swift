//
//  LiquidButton.swift
//  Video Progress Tracker
//
//  iOS 26 Liquid UI - Glassmorphic Button Component
//

import SwiftUI

/// A floating, glassy button with spring animations
struct LiquidButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed: Bool = false
    
    enum ButtonStyle {
        case primary    // Main action button
        case secondary  // Secondary action
        case subtle     // Less prominent
        case destructive // Delete/remove actions
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 14)
            .background(buttonBackground)
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.snappy(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Style Properties
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .primary: return 24
        case .secondary, .destructive: return 20
        case .subtle: return 16
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .subtle:
            return .secondary
        case .destructive:
            return .white
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Capsule().fill(.thinMaterial)
        case .subtle:
            Capsule().fill(.ultraThinMaterial)
        case .destructive:
            LinearGradient(
                colors: [Color.red, Color.red.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.blue.opacity(0.3)
        case .secondary, .subtle:
            return Color.black.opacity(0.1)
        case .destructive:
            return Color.red.opacity(0.3)
        }
    }
}

// MARK: - Icon Button Variant

struct LiquidIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var style: LiquidButton.ButtonStyle = .secondary
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(buttonBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.snappy(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary, .subtle: return .primary
        case .destructive: return .red
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            Circle().fill(Color.blue)
        case .secondary:
            Circle().fill(.thinMaterial)
        case .subtle:
            Circle().fill(.ultraThinMaterial)
        case .destructive:
            Circle().fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LiquidButton(title: "Primary Action", icon: "play.fill", style: .primary) {}
        
        LiquidButton(title: "Secondary", icon: "bookmark", style: .secondary) {}
        
        LiquidButton(title: "Subtle Action", style: .subtle) {}
        
        LiquidButton(title: "Delete", icon: "trash", style: .destructive) {}
        
        LiquidButton(title: "Loading...", style: .primary, isLoading: true) {}
        
        HStack(spacing: 16) {
            LiquidIconButton(icon: "play.fill", style: .primary) {}
            LiquidIconButton(icon: "heart", style: .secondary) {}
            LiquidIconButton(icon: "square.and.arrow.up", style: .subtle) {}
            LiquidIconButton(icon: "trash", style: .destructive) {}
        }
    }
    .padding()
    .liquidBackground()
}
