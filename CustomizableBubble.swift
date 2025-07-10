//
//  CustomizableBubble.swift
//  BubbleNavApp_2.0
//
//  Created by DPI Student 141 on 7/6/25.
//
import SwiftUI
// MARK:  This code allows you to create a bubble button and customize its size, icon image, and position wherever it is called

struct CustomizableBubble: View {
    
    // MARK: Properties
    // These properties allow easy customization of each bubble
    let contentImageName: String    // The icon/image that goes inside the bubble
    let label: String              // Text label below the bubble
    let bubbleSize: CGFloat        // Size of the bubble (easily adjustable)
    let position: CGPoint          // X,Y position of the bubble (easily adjustable)
    let action: () -> Void         // Action to perform when bubble is tapped
    
    // MARK: Animation State Variables
    @State private var wobbleOffset = CGSize.zero  // Tracks the wobble animation offset
    @State private var scale: Double = 1.0         // Tracks the scale for tap animation
    @State private var rotation: Double = 0.0      // Tracks the rotation animation
    
    var body: some View {
        Button(action: {
            // MARK: Tap Animation
            // Create a brief "press" effect when bubble is tapped
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 0.90  // Shrink slightly
            }
            // Return to normal size and execute the action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    scale = 1.0  // Return to normal size
                }
                action()  // Execute the bubble's action
            }
        }) {
            VStack(spacing: 8) {
                // MARK: Stacked Images (Bubble + Content)
                ZStack {
                    // Background bubble image (your custom bubble_icon)
                    Image("bubble_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: bubbleSize, height: bubbleSize)
                    
                    // Content image stacked on top of the bubble

                    Image(contentImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: bubbleSize - 25, height: bubbleSize - 25)
                        .font(.system(size: bubbleSize * 0.4))  // Size relative to bubble
                        .shadow(color: .blue.opacity(1.2), radius: 3)
                }
                // Apply shadow to the entire stacked image group
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // MARK: Label Text
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(width: bubbleSize)  // Match bubble width for alignment
            }
            // MARK: Apply All Animations to Entire VStack
            // This keeps the bubble and label moving together as one unit
            .scaleEffect(scale)           // Tap scaling animation
            .rotationEffect(.degrees(rotation))  // Gentle rotation animation
            .offset(wobbleOffset)         // Wobble/floating animation
        }
        .buttonStyle(PlainButtonStyle())  // Remove default button styling
        .position(position)  // Set the bubble's position on screen
        .onAppear {
            // Start the gentle floating animation when bubble appears
            startGentleFloatingAnimation()
        }
    }
    
    // MARK: Animation Functions
    /// Creates a very subtle floating animation with random timing
    private func startGentleFloatingAnimation() {
        // Random delay so bubbles don't all animate in sync
        let randomDelay = Double.random(in: 0...1)
        
        // MARK: Wobble Animation
        // Very subtle movement to simulate floating
        withAnimation(
            Animation.easeInOut(duration: Double.random(in: 4...5))
                .repeatForever(autoreverses: true)  // Goes back and forth
                .delay(randomDelay)
        ) {
            wobbleOffset = CGSize(
                width: Double.random(in: -2...2),   // Small horizontal movement
                height: Double.random(in: -2...2)   // Small vertical movement
            )
        }
        
        // Rotation Animation
        // Very subtle rotation for natural floating effect
        let rotationDelay = Double.random(in: 0...1)
        withAnimation(
            Animation.easeInOut(duration: Double.random(in: 6...7))
                .repeatForever(autoreverses: true)  // Goes back and forth
                .delay(rotationDelay)
        ) {
            rotation = Double.random(in: -2...2)  // Tiny rotation angle
        }
    }
}

// MARK: Preview
#Preview {
    // Example of how to use the customizable bubble
    CustomizableBubble(
        contentImageName: "first_icon",
        label: "Sample",
        bubbleSize: 80,
        position: CGPoint(x: 200, y: 300),
        action: {
            print("Sample bubble tapped!")
        }
    )
}
