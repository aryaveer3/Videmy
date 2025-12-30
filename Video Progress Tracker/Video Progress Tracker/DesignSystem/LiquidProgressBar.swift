//
//  LiquidProgressBar.swift
//  Video Progress Tracker
//
//  iOS 26 Liquid UI - Animated Progress Bar Component
//

import SwiftUI

/// A smooth, animated progress bar with glassmorphic styling
struct LiquidProgressBar: View {
    let progress: Double
    var tint: Color = .blue
    var height: CGFloat = 8
    var showPercentage: Bool = false
    var animate: Bool = true
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0
    
    private var safeProgress: Double {
        guard !progress.isNaN && !progress.isInfinite else { return 0 }
        return max(0, min(1, progress))
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                    
                    // Fill
                    Capsule()
                        .fill(progressGradient)
                        .frame(width: max(0, geometry.size.width * (animate ? animatedProgress : safeProgress)))
                        .shadow(color: tint.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: height)
            
            if showPercentage {
                Text("\(Int(safeProgress * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            if animate && !reduceMotion {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedProgress = safeProgress
                }
            } else {
                animatedProgress = safeProgress
            }
        }
        .onChange(of: safeProgress) { _, newValue in
            if animate && !reduceMotion {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [tint, tint.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Circular Progress Variant

struct LiquidCircularProgress: View {
    let progress: Double
    var tint: Color = .blue
    var lineWidth: CGFloat = 4
    var size: CGFloat = 32
    var showPercentage: Bool = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0
    
    private var safeProgress: Double {
        guard !progress.isNaN && !progress.isInfinite else { return 0 }
        return max(0, min(1, progress))
    }
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(.ultraThinMaterial, lineWidth: lineWidth)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            
            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(safeProgress * 100))")
                    .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedProgress = safeProgress
                }
            } else {
                animatedProgress = safeProgress
            }
        }
        .onChange(of: safeProgress) { _, newValue in
            if !reduceMotion {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }
    
    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [tint, tint.opacity(0.7), tint],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Linear Progress")
                .font(.headline)
            
            LiquidProgressBar(progress: 0.7, showPercentage: true)
            LiquidProgressBar(progress: 0.45, tint: .green)
            LiquidProgressBar(progress: 1.0, tint: .orange, height: 12)
        }
        
        VStack(spacing: 16) {
            Text("Circular Progress")
                .font(.headline)
            
            HStack(spacing: 20) {
                LiquidCircularProgress(progress: 0.75, showPercentage: true)
                LiquidCircularProgress(progress: 0.5, tint: .green, size: 40, showPercentage: true)
                LiquidCircularProgress(progress: 1.0, tint: .orange, size: 48, showPercentage: true)
            }
        }
    }
    .padding()
    .liquidBackground()
}
