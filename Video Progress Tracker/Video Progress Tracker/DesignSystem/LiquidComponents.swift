//
//  LiquidComponents.swift
//  Video Progress Tracker
//
//  iOS 26 Liquid UI - Additional Reusable Components
//

import SwiftUI

// MARK: - Liquid Section Header

struct LiquidSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Liquid List Row

struct LiquidListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var leading: Leading
    var trailing: Trailing
    var isHighlighted: Bool = false
    
    init(
        title: String,
        subtitle: String? = nil,
        isHighlighted: Bool = false,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isHighlighted = isHighlighted
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            leading
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isHighlighted ? .blue : .primary)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 8)
            
            trailing
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Liquid Divider

struct LiquidDivider: View {
    var opacity: Double = 0.15
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0),
                        Color.primary.opacity(opacity),
                        Color.primary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Liquid Status Badge

struct LiquidStatusBadge: View {
    let text: String
    var color: Color = .blue
    var style: BadgeStyle = .filled
    
    enum BadgeStyle {
        case filled
        case subtle
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badgeBackground)
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    private var badgeBackground: some View {
        switch style {
        case .filled:
            Capsule().fill(color)
        case .subtle:
            Capsule().fill(color.opacity(0.15))
        }
    }
}

// MARK: - Liquid Empty State

struct LiquidEmptyState: View {
    let icon: String
    let title: String
    var message: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if let action = action {
                LiquidButton(title: actionLabel, style: .primary, action: action)
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Liquid Thumbnail

struct LiquidThumbnail: View {
    let url: String?
    var size: CGSize = CGSize(width: 120, height: 68)
    var cornerRadius: CGFloat = 12
    var overlay: AnyView? = nil
    
    private var safeSize: CGSize {
        CGSize(
            width: size.width.isNaN || size.width.isInfinite || size.width <= 0 ? 120 : size.width,
            height: size.height.isNaN || size.height.isInfinite || size.height <= 0 ? 68 : size.height
        )
    }
    
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderView
            case .empty:
                placeholderView
                    .overlay(ProgressView().scaleEffect(0.7))
            @unknown default:
                placeholderView
            }
        }
        .frame(width: safeSize.width, height: safeSize.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .overlay(overlay)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary.opacity(0.5))
            )
    }
}

// MARK: - Animated Visibility Modifier

extension View {
    func liquidTransition() -> some View {
        self.transition(
            .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.spring(response: 0.35, dampingFraction: 0.8)),
                removal: .opacity.animation(.easeOut(duration: 0.2))
            )
        )
    }
    
    func liquidAppear(delay: Double = 0) -> some View {
        self.modifier(LiquidAppearModifier(delay: delay))
    }
}

struct LiquidAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                        isVisible = true
                    }
                }
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LiquidSectionHeader(title: "Continue Watching", subtitle: "Pick up where you left off") {}
            
            LiquidCard {
                LiquidListRow(
                    title: "Introduction to SwiftUI",
                    subtitle: "12:34",
                    isHighlighted: true,
                    leading: {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    },
                    trailing: {
                        LiquidStatusBadge(text: "75%", style: .subtle)
                    }
                )
            }
            
            LiquidDivider()
            
            HStack {
                LiquidStatusBadge(text: "In Progress", color: .blue, style: .subtle)
                LiquidStatusBadge(text: "Completed", color: .green, style: .filled)
            }
            
            LiquidEmptyState(
                icon: "book.closed",
                title: "No Courses Yet",
                message: "Import a YouTube playlist to get started",
                action: {}
            )
        }
        .padding()
    }
    .liquidBackground()
}
