//
//  FifthView.swift
//  BubbleNavApp_2.0
//
//  Created by DPI Student 141 on 7/8/25.
//
import SwiftUI

// MARK: - Bubble Button Components 
struct BackwardBubble: View {
    let bubbleSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image("bubble_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: bubbleSize, height: bubbleSize)
                Image(systemName: "arrowshape.backward.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(width: bubbleSize - 15, height: bubbleSize - 15)
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Model
struct Goal: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    var isCompleted: Bool = false
}

// MARK: - Goals Page View
struct GoalsView: View {
    @Binding var isPresented: Bool
    @State private var goals = [
        Goal(title: "Drink 8 glasses of water daily", description: "Stay hydrated throughout the day for better energy and health"),
        Goal(title: "Practice 10 minutes of meditation", description: "Take time to center yourself and reduce stress"),
        Goal(title: "Take a 30-minute walk", description: "Get some fresh air and light exercise to boost your mood"),
        Goal(title: "Write 3 things I'm grateful for", description: "Focus on positive aspects of your day and life"),
        Goal(title: "Eat 5 servings of fruits/vegetables", description: "Nourish your body with colorful, healthy foods"),
        Goal(title: "Get 8 hours of sleep", description: "Prioritize rest for mental and physical recovery"),
        Goal(title: "Practice positive self-talk", description: "Be kind to yourself and challenge negative thoughts"),
        Goal(title: "Connect with a friend or family member", description: "Maintain meaningful relationships and social connections")
    ]

    //MARK: Body View
    var body: some View {
        
        BackgroundContainer {
            VStack(alignment: .leading) {
                // Header with back button and title
                HStack {
                    BackwardBubble(bubbleSize: 45) {
                        isPresented = false
                    }
                    
                    Spacer()
                    
                    Text("My Goals")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 20, height: 150)
                }
                .padding(.horizontal, 40)
                
                // Goals List
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(goals.indices, id: \.self) { index in
                            GoalCard(
                                goal: $goals[index],
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        goals[index].isCompleted.toggle()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Extra padding for safe area
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Goal Card Component
struct GoalCard: View {
    @Binding var goal: Goal
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 15) {
                // Checkmark Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if goal.isCompleted {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: goal.isCompleted)
                
                // Goal Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .strikethrough(goal.isCompleted, color: .white.opacity(0.8))
                    
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        goal.isCompleted ?
                        Color.green.opacity(0.2) :
                        Color.black.opacity(0.3)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        goal.isCompleted ?
                        Color.green.opacity(0.4) :
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(goal.isCompleted ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: goal.isCompleted)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    GoalsView(isPresented: .constant(true))
}
