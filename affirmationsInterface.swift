import SwiftUI

// MARK: - Models

struct Affirmation: Identifiable, Equatable {
    let id: UUID
    var text: String
    var category: CategoryKey
    var isFavorite: Bool = false
    var timesUsed: Int = 0
    
    enum CategoryKey: String, CaseIterable, Identifiable {
        case selfLove = "self_love"
        case bodyAcceptance = "body_acceptance"
        case strength
        case recovery
        case mindfulness
        case selfWorth = "self_worth"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .selfLove: return "Self Love"
            case .bodyAcceptance: return "Body Acceptance"
            case .strength: return "Strength"
            case .recovery: return "Recovery"
            case .mindfulness: return "Mindfulness"
            case .selfWorth: return "Self Worth"
            }
        }
        
        var color: Color {
            switch self {
            case .selfLove: return Color.pink.opacity(0.3)
            case .bodyAcceptance: return Color.purple.opacity(0.3)
            case .strength: return Color.red.opacity(0.3)
            case .recovery: return Color.green.opacity(0.3)
            case .mindfulness: return Color.blue.opacity(0.3)
            case .selfWorth: return Color.yellow.opacity(0.3)
            }
        }
    }
}

enum AffirmationFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case selfLove = "self_love"
    case bodyAcceptance = "body_acceptance"
    case strength
    case recovery
    case mindfulness
    case selfWorth = "self_worth"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All Affirmations"
        case .favorites: return "Favorites"
        case .selfLove: return "Self Love"
        case .bodyAcceptance: return "Body Acceptance"
        case .strength: return "Strength"
        case .recovery: return "Recovery"
        case .mindfulness: return "Mindfulness"
        case .selfWorth: return "Self Worth"
        }
    }
}

// MARK: - ViewModel (Simulating async data operations)

@MainActor
class AffirmationsViewModel: ObservableObject {
    @Published var affirmations: [Affirmation] = []
    @Published var loading: Bool = true
    @Published var showForm: Bool = false
    @Published var currentAffirmation: Affirmation? = nil
    @Published var filter: AffirmationFilter = .all
    
    // Form state
    @Published var formText: String = ""
    @Published var formCategory: Affirmation.CategoryKey? = nil
    
    // Sample affirmations
    let sampleAffirmations: [Affirmation] = [
        Affirmation(id: UUID(), text: "I am worthy of love and respect exactly as I am", category: .selfLove),
        Affirmation(id: UUID(), text: "My body is my home and I treat it with kindness", category: .bodyAcceptance),
        Affirmation(id: UUID(), text: "I am stronger than my struggles and capable of healing", category: .strength),
        Affirmation(id: UUID(), text: "Every day I take steps toward wellness and recovery", category: .recovery),
        Affirmation(id: UUID(), text: "I breathe deeply and find peace in this moment", category: .mindfulness),
        Affirmation(id: UUID(), text: "My worth is not determined by my appearance", category: .selfWorth),
    ]
    
    init() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        loading = true
        // Simulate network fetch delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // For demo, just load local sample affirmations or use persisted data
        // In real app, replace with actual data loading
        
        // Here just use the current affirmations or sample if empty
        if affirmations.isEmpty {
            affirmations = sampleAffirmations
        }
        loading = false
    }
    
    func createAffirmation() async {
        guard let category = formCategory, !formText.isEmpty else { return }
        
        let new = Affirmation(id: UUID(), text: formText, category: category)
        affirmations.append(new)
        resetForm()
        showForm = false
    }
    
    func resetForm() {
        formText = ""
        formCategory = nil
    }
    
    func toggleFavorite(affirmation: Affirmation) {
        if let idx = affirmations.firstIndex(of: affirmation) {
            affirmations[idx].isFavorite.toggle()
        }
    }
    
    func useAffirmation(_ affirmation: Affirmation) {
        if let idx = affirmations.firstIndex(of: affirmation) {
            affirmations[idx].timesUsed += 1
            currentAffirmation = affirmations[idx]
        }
    }
    
    func createSampleAffirmations() async {
        affirmations.append(contentsOf: sampleAffirmations)
    }
    
    var filteredAffirmations: [Affirmation] {
        switch filter {
        case .all:
            return affirmations
        case .favorites:
            return affirmations.filter { $0.isFavorite }
        default:
            return affirmations.filter { $0.category.rawValue == filter.rawValue }
        }
    }
}

// MARK: - View

struct AffirmationsView: View {
    @StateObject private var vm = AffirmationsViewModel()
    
    var body: some View {
        NavigationView {
            if vm.loading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                       
                        if let current = vm.currentAffirmation {
                            currentAffirmationView(current)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        actionsView
                        
                        if vm.showForm {
                            createFormView
                                .transition(.opacity)
                        }
                        
                        if vm.filteredAffirmations.isEmpty {
                            emptyStateView
                        } else {
                            affirmationsGrid
                        }
                    }
                    .padding()
                }
                .navigationTitle("Daily Affirmations")
            }
        }
    }
    
    // MARK: - Components
    
    
    private func currentAffirmationView(_ affirmation: Affirmation) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.blue)
            
            Text("\"\(affirmation.text)\"")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.blue)
            
            HStack(spacing: 12) {
                Text(affirmation.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(affirmation.category.color)
                    .clipShape(Capsule())
                
                Button {
                    withAnimation {
                        vm.currentAffirmation = nil
                    }
                } label: {
                    Label("Done", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .padding(6)
                        .overlay(
                            Capsule().stroke(Color.blue, lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
    
    private var actionsView: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation {
                    vm.showForm.toggle()
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .accessibilityLabel("Add new affirmation")
                    .accessibilityHint("Opens the form to create a new affirmation")
            }
            
            if vm.affirmations.isEmpty {
                Button {
                    Task {
                        await vm.createSampleAffirmations()
                    }
                } label: {
                    Text("Add Sample Affirmations")
                        .padding(8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                }
            }
            
            Picker("Filter", selection: $vm.filter) {
                Text("All Affirmations").tag(AffirmationFilter.all)
                Text("Favorites").tag(AffirmationFilter.favorites)
                ForEach(Affirmation.CategoryKey.allCases, id: \.self) { cat in
                    Text(cat.displayName).tag(AffirmationFilter(rawValue: cat.rawValue) ?? .all)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    private var createFormView: some View {
        VStack(spacing: 16) {
            Text("Create New Affirmation")
                .font(.headline)
                .foregroundColor(.blue)
            
            TextField("I am...", text: $vm.formText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Select Category", selection: $vm.formCategory) {
                Text("Select category").tag(Affirmation.CategoryKey?.none)
                ForEach(Affirmation.CategoryKey.allCases) { cat in
                    Text(cat.displayName).tag(Optional(cat))
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            HStack(spacing: 12) {
                Button("Create!") {
                    Task {
                        await vm.createAffirmation()
                    }
                }
                .disabled(vm.formText.isEmpty || vm.formCategory == nil)
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    withAnimation {
                        vm.showForm = false
                        vm.resetForm()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
    
    private var affirmationsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
            ForEach(vm.filteredAffirmations) { affirmation in
                AffirmationCardView(
                    affirmation: affirmation,
                    toggleFavorite: { vm.toggleFavorite(affirmation: affirmation) },
                    useAffirmation: { vm.useAffirmation(affirmation) }
                )
                .animation(.spring(), value: vm.filteredAffirmations)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            
            Text(vm.filter == .all
                 ? "No affirmations yet. Create your first one!"
                 : "No affirmations in this category yet.")
                .foregroundColor(.blue.opacity(0.7))
                .font(.title3)
            
            Button {
                withAnimation {
                    vm.showForm = true
                }
            } label: {
                Label("Create Your First Affirmation", systemImage: "plus")
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Affirmation Card

struct AffirmationCardView: View {
    let affirmation: Affirmation
    let toggleFavorite: () -> Void
    let useAffirmation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(affirmation.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(affirmation.category.color)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button(action: toggleFavorite) {
                    Image(systemName: affirmation.isFavorite ? "fish.fill" : "fish")
                        .foregroundColor(affirmation.isFavorite ? .yellow : .orange)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            Text("\"\(affirmation.text)\"")
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .lineLimit(3)
            
            HStack {
                Text("Used \(affirmation.timesUsed) times")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))
                
                Spacer()
                
                Button("Use This", action: useAffirmation)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
        .onTapGesture {
            // Optional: tap card to select or show details
        }
    }
}

// MARK: - Preview

struct AffirmationsView_Previews: PreviewProvider {
    static var previews: some View {
        AffirmationsView()
    }
}
