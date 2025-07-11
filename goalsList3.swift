import SwiftUI
import UIKit

// 1. Enums
enum GoalCategory: String, CaseIterable, Identifiable {
    case selfCare = "self_care"
    case therapy, nutrition, exercise, social, mindfulness, recovery
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .selfCare: return "Self Care"
        case .therapy: return "Therapy"
        case .nutrition: return "Nutrition"
        case .exercise: return "Exercise"
        case .social: return "Social"
        case .mindfulness: return "Mindfulness"
        case .recovery: return "Recovery"
        }
    }
    var color: Color {
        switch self {
        case .selfCare: return .pink
        case .therapy: return .purple
        case .nutrition: return .green
        case .exercise: return .blue
        case .social: return .yellow
        case .mindfulness: return .indigo
        case .recovery: return .mint
        }
    }
}
enum GoalStatus: String, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed
    case paused
    var icon: Image {
        switch self {
        case .notStarted: return Image(systemName: "clock")
        case .inProgress: return Image(systemName: "play.fill")
        case .completed: return Image(systemName: "checkmark.circle.fill")
        case .paused: return Image(systemName: "pause.fill")
        }
    }
    var label: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// 2. Goal Model
struct Goal: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var category: GoalCategory
    var targetDate: Date?
    var status: GoalStatus
    var progressPercentage: Int
}

// 3. ViewModel
class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var filter: String = "all"
    @Published var showForm = false
    @Published var editingGoal: Goal? = nil
    @Published var formData = Goal(id: UUID(), title: "", description: "", category: .selfCare, targetDate: nil, status: .notStarted, progressPercentage: 0)
    
    // Toast state
    @Published var showToast = false
    @Published var toastMessage = ""
    
    // Haptic feedback generator
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    var filteredGoals: [Goal] {
        switch filter {
        case "active":
            return goals.filter { $0.status == .notStarted || $0.status == .inProgress }
        case "completed":
            return goals.filter { $0.status == .completed }
        case let cat where GoalCategory.allCases.map({ $0.rawValue }).contains(cat):
            return goals.filter { $0.category.rawValue == cat }
        default:
            return goals
        }
    }
    
    func addOrUpdateGoal() {
        if let index = goals.firstIndex(where: { $0.id == formData.id }) {
            goals[index] = formData
        } else {
            goals.append(formData)
        }
        resetForm()
    }
    
    func editGoal(_ goal: Goal) {
        editingGoal = goal
        formData = goal
        showForm = true
    }
    
    func resetForm() {
        formData = Goal(id: UUID(), title: "", description: "", category: .selfCare, targetDate: nil, status: .notStarted, progressPercentage: 0)
        editingGoal = nil
        showForm = false
    }
    
    func updateStatus(_ goal: Goal, to newStatus: GoalStatus) {
        if let i = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[i].status = newStatus
            if newStatus == .completed {
                goals[i].progressPercentage = 100
                showCompletionToast()
            } else if newStatus == .notStarted {
                goals[i].progressPercentage = 0
            }
        }
    }
    
    func updateProgress(_ goal: Goal, newProgress: Int) {
        if let i = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[i].progressPercentage = newProgress
            if newProgress == 100 {
                goals[i].status = .completed
                showCompletionToast()
            } else if newProgress > 0 && goals[i].status == .notStarted {
                goals[i].status = .inProgress
            }
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        feedbackGenerator.notificationOccurred(.warning) // Haptic feedback for delete
    }
    
    private func showCompletionToast() {
        toastMessage = "Way to go!"
        withAnimation {
            showToast = true
        }
        feedbackGenerator.notificationOccurred(.success) // Haptic feedback for success
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showToast = false
            }
        }
    }
}

// 4. Helper for optional DatePicker extension Binding
extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith fallbackValue: Value) {
        self.init(
            get: { source.wrappedValue ?? fallbackValue },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

// 5. Toast Modifier
extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isShowing.wrappedValue {
                Text(message)
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing.wrappedValue)
    }
}

// 6. Main View
struct GoalsView: View {
    @StateObject private var viewModel = GoalViewModel()
    @State private var showDeleteConfirmation = false
    @State private var goalToDelete: Goal? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    controls
                    
                    if viewModel.showForm {
                        goalForm
                    }
                    
                    if viewModel.filteredGoals.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.filteredGoals) { goal in
                            goalCard(goal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Goals")
            // Delete confirmation alert
            .alert("Are you sure you want to delete this goal?\nYou can do it!", isPresented: $showDeleteConfirmation, presenting: goalToDelete) { goal in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    withAnimation {
                        if let goal = goalToDelete {
                            viewModel.deleteGoal(goal)
                        }
                    }
                }
            }
            .toast(isShowing: $viewModel.showToast, message: viewModel.toastMessage)
        }
    }
    
    private var controls: some View {
        HStack {
            Button {
                viewModel.showForm.toggle()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .accessibilityLabel("Add new goal")
                    .accessibilityHint("Opens the form to create a new goal")
            }
            Menu {
                Button("All Goals") { viewModel.filter = "all" }
                Button("Active Goals") { viewModel.filter = "active" }
                Button("Completed Goals") { viewModel.filter = "completed" }
                ForEach(GoalCategory.allCases) { category in
                    Button(category.displayName) { viewModel.filter = category.rawValue }
                }
            } label: {
                Label("Filter", systemImage: "slider.horizontal.3")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .accessibilityLabel("Filter goals")
                    .accessibilityHint("Choose which goals to display")
            }
        }
    }
    
    private var goalForm: some View {
        VStack(spacing: 12) {
            Text(viewModel.editingGoal == nil ? "Create Goal" : "Edit Goal")
                .font(.headline)
            TextField("Title", text: $viewModel.formData.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Goal title")
            TextField("Description", text: $viewModel.formData.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Goal description")
            Picker("Category", selection: $viewModel.formData.category) {
                ForEach(GoalCategory.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .accessibilityLabel("Goal category picker")
            DatePicker(
                "Target Date",
                selection: Binding($viewModel.formData.targetDate, replacingNilWith: Date()),
                displayedComponents: .date
            )
            .accessibilityLabel("Goal target date picker")
            HStack {
                Button("Let's do this!") {
                    viewModel.addOrUpdateGoal()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Submit goal")
                
                Button("Cancel") {
                    viewModel.resetForm()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Cancel goal creation")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(20)
    }
    
    private func goalCard(_ goal: Goal) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goal.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .accessibilityLabel("Goal title: \(goal.title)")
                    Spacer()
                    Button("Edit") {
                        viewModel.editGoal(goal)
                    }
                    .accessibilityLabel("Edit goal titled \(goal.title)")
                    
                    // Trash button for delete
                    Button {
                        goalToDelete = goal
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(6)
                    }
                    .accessibilityLabel("Delete goal titled \(goal.title)")
                }
                Text(goal.description)
                    .font(.subheadline)
                    .accessibilityLabel("Goal description: \(goal.description)")
                HStack {
                    Text(goal.category.displayName)
                        .padding(6)
                        .background(goal.category.color.opacity(0.2))
                        .cornerRadius(10)
                        .accessibilityLabel("Category: \(goal.category.displayName)")
                    Text(goal.status.label)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .accessibilityLabel("Status: \(goal.status.label)")
                    goal.status.icon
                }
                if let target = goal.targetDate {
                    Label("Target: \(target.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .accessibilityLabel("Target date: \(target.formatted(date: .abbreviated, time: .omitted))")
                }
                ProgressView(value: Float(goal.progressPercentage), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accessibilityLabel("Progress: \(goal.progressPercentage) percent")
                
                // Checkbox for completion toggle
                Button(action: {
                    let isCompleted = goal.status == .completed
                    if isCompleted {
                        viewModel.updateStatus(goal, to: .notStarted)
                        viewModel.updateProgress(goal, newProgress: 0)
                    } else {
                        viewModel.updateProgress(goal, newProgress: 100)
                    }
                }) {
                    HStack {
                        Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(goal.status == .completed ? .blue : .gray)
                        Text("Completed")
                    }
                }
                .accessibilityLabel("Mark goal \(goal.title) as complete")
                .buttonStyle(PlainButtonStyle())

            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
        }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundColor(.green.opacity(0.25))
                .accessibilityHidden(true)
            Text("No goals to show.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Preview
struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
    }
}
