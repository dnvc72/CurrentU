import SwiftUI

struct ThoughtReframeView: View {
    @State private var userThought: String = ""
    @State private var selectedEmotion: String = ""
    
    // ADDED: multiple emotions tracking and input text field
    @State private var selectedEmotions: Set<String> = []
    @State private var emotionInput: String = ""
    
    @State private var friendResponse: String = ""
    @State private var showReframe: Bool = false
    struct SavedReframe: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let date: Date
    }
    @State private var savedReframes: [SavedReframe] = []
    @State private var showDeleteConfirmation: SavedReframe? = nil
    @State private var showGrounding: Bool = false
    
    let commonThoughts = [
        "I'm uncomfortable in my body",
        "I ate too much",
        "I feel gross",
        "My clothes don't fit right",
        "Why do I look like this?",
        "I don’t look like I used to",
        "I wish I could disappear",
        "I look different from everyone else",
        "I hate how I look in photos",
        "I hate how I look in the mirror",
        "People are judging my body",
        "I should’ve skipped that meal"
    ]

    let emotions = [
        "Sad", "Angry", "Anxious", "Lonely", "Insecure",
        "Overwhelmed", "Embarrassed", "Stuck", "Ashamed", "Tired", "Guilty", "Frustrated"
    ]

    let groundingActivities = [
        "Stretch to your favorite song",
        "Write yourself a letter",
        "Drink water",
        "Go for a walk outside",
        "Call or text a friend"
    ]

    func convertToFirstPerson(_ text: String) -> String {
        var result = text

        // 1. Replace contractions first — apostrophes break word boundaries so no \b here.
        // Use case-insensitive matching
        let contractionReplacements: [String: String] = [
            "(?i)you're": "I'm",
            "(?i)you’re": "I'm",  // smart apostrophe variant
            "(?i)you'd": "I'd",
            "(?i)you’d": "I'd",
            "(?i)you've": "I've",
            "(?i)you’ve": "I've",
            "(?i)you'll": "I'll",
            "(?i)you’ll": "I'll"
        ]

        for (pattern, replacement) in contractionReplacements {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: [.regularExpression])
        }

        // 2. Replace longer phrases with word boundaries.
        let phraseReplacements: [String: String] = [
            "(?i)\\bi love you\\b": "I love myself",
            "(?i)\\bproud of you\\b": "proud of myself",
            "(?i)\\bremind you\\b": "remind myself",
            "(?i)\\bcare about you\\b": "care about myself",
            "(?i)\\bfor you\\b": "for myself",
            "(?i)\\byou are beautiful\\b": "I am beautiful",
            "(?i)\\byou are worthy\\b": "I am worthy",
            "(?i)\\byou are enough\\b": "I am enough",
            "(?i)\\byou are safe\\b": "I am safe",
            "(?i)\\byou are loved\\b": "I am loved",
            "(?i)\\byou are strong\\b": "I am strong",
            "(?i)\\byou matter\\b": "I matter",
            "(?i)\\byou belong\\b": "I belong",
            "(?i)\\byou got this\\b": "I got this",
            "(?i)(support|love|remind|trust|forgive|care about|help|thank|appreciate) you\\b": "$1 myself"
        ]

        for (pattern, replacement) in phraseReplacements {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: [.regularExpression])
        }

        // 3. Replace standalone pronouns — exclude 'you' followed by apostrophe to avoid contractions.
        let pronounReplacements: [String: String] = [
            "\\byourself\\b": "myself",
            "\\bYourself\\b": "Myself",
            "\\byour\\b": "my",
            "\\bYour\\b": "My",
            "\\byours\\b": "mine",
            "\\bYours\\b": "Mine",
            // Negative lookahead (?!') prevents matching 'you' inside contractions like "you're"
            "\\byou(?!['’])\\b": "I",
            "\\bYou(?!['’])\\b": "I"
        ]

        for (pattern, replacement) in pronounReplacements {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: [.regularExpression])
        }

        // Capitalize standalone 'i'
        if let regex = try? NSRegularExpression(pattern: "\\bi\\b", options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "I")
        }

        // Capitalize first letter of the string
        if let first = result.first {
            result.replaceSubrange(result.startIndex...result.startIndex, with: String(first).uppercased())
        }

        // Remove trailing "it" after "need" or "need to"
        result = result.replacingOccurrences(of: "(?i)(need (it|to it))\\b", with: "need", options: .regularExpression)

        return result
    }


    var reframe: String {
        guard !userThought.isEmpty, !friendResponse.isEmpty else { return "" }
        let personalized = convertToFirstPerson(friendResponse)
        
        // Use all selectedEmotions if not empty, else fallback to selectedEmotion
        let emotionsList: String
        if !selectedEmotions.isEmpty {
            let sortedEmotions = selectedEmotions.sorted().map { $0.lowercased() }
            if sortedEmotions.count == 1 {
                emotionsList = sortedEmotions[0]
            } else if sortedEmotions.count == 2 {
                emotionsList = "\(sortedEmotions[0]) and \(sortedEmotions[1])"
            } else {
                // More than 2 emotions: join with commas, add "and" before last
                let allButLast = sortedEmotions.dropLast().joined(separator: ", ")
                let last = sortedEmotions.last!
                emotionsList = "\(allButLast), and \(last)"
            }
        } else if !selectedEmotion.isEmpty {
            emotionsList = selectedEmotion.lowercased()
        } else {
            return "" // no emotions selected so no reframe
        }

        
        return "I feel \(emotionsList), but this feeling doesn’t define me. \(personalized)"
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            Text("What’s on your mind?")
                                .font(.headline)
                            
                            TextEditor(text: $userThought)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.5)))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 120)), count: 2), spacing: 10) {
                                ForEach(commonThoughts, id: \.self) { thought in
                                    Button(action: {
                                        userThought = thought
                                    }) {
                                        Text(thought)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        Group {
                            Text("How do you feel?")
                                .font(.headline)
                            
                            TextField("List emotions", text: $emotionInput, onCommit: {
                                // Parse input text into emotions set
                                let inputEmotions = emotionInput
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).capitalized }
                                    .filter { !$0.isEmpty }
                                selectedEmotions = Set(inputEmotions)
                                
                                // Sync selectedEmotion for backward compatibility
                                if selectedEmotions.count == 1 {
                                    selectedEmotion = selectedEmotions.first ?? ""
                                } else {
                                    selectedEmotion = ""
                                }
                                
                                // Update cleaned input text
                                emotionInput = selectedEmotions.sorted().joined(separator: ", ")
                            })
                            .padding(.top, 8)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.5)))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 100)), count: 3), spacing: 10) {
                                ForEach(emotions, id: \.self) { emotion in
                                    Button(action: {
                                        // Toggle emotion in selectedEmotions
                                        if selectedEmotions.contains(emotion) {
                                            selectedEmotions.remove(emotion)
                                        } else {
                                            selectedEmotions.insert(emotion)
                                        }
                                        // Sync selectedEmotion for backward compatibility but will not override when using multiple emotions
                                        if selectedEmotions.count == 1 {
                                            selectedEmotion = selectedEmotions.first ?? ""
                                        } else {
                                            selectedEmotion = ""
                                        }
                                        // Update emotionInput textfield
                                        emotionInput = selectedEmotions.sorted().joined(separator: ", ")
                                    }) {
                                        Text(emotion)
                                            .frame(maxWidth: .infinity, minHeight: 40)
                                            .padding(8)
                                            .background(selectedEmotions.contains(emotion) ? Color.blue.opacity(0.3) : Color.blue.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            
                        }
                        
                        Group {
                            Text("What would you say to a friend who was feeling like this?")
                                .font(.headline)
                            TextEditor(text: $friendResponse)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.5)))
                        }
                        
                        if showReframe {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your Reframe:")
                                    .font(.headline)
                                Text(reframe)
                                    .italic()
                                    .padding()
                                    .background(Color.yellow.opacity(0.2))
                                    .cornerRadius(10)
                                
                                Button("Save") {
                                    if !savedReframes.contains(where: { $0.text == reframe }) {
                                        savedReframes.append(SavedReframe(text: reframe, date: Date()))
                                    }
                                }
                                
                            }
                        } else {
                            Button("Reframe") {
                                showReframe = true
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                        }
                        
                        if showReframe {
                            Button("Ground Myself") {
                                showGrounding.toggle()
                            }
                            .padding(.top)
                        }
                        
                        if showGrounding {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Try one of these:")
                                    .font(.subheadline)
                                ForEach(groundingActivities, id: \.self) { activity in
                                    Text("• " + activity)
                                }
                            }
                        }
                        
                        if !savedReframes.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("My Reframed Thoughts")
                                    .font(.headline)
                                ForEach(savedReframes) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.text)
                                                .padding(5)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(8)
                                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Button(action: {
                                            showDeleteConfirmation = item
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding(.top)
                        }
                        
                        Button("Safety Plan") {
                            //link to safety plan
                        }
                        .foregroundColor(.red)
                        .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle("Thought Reframe")
                
                //Delete pop-up
                ZStack {
                    if let itemToDelete = showDeleteConfirmation {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            Text("Are you sure you want to delete this reframe?")
                                .multilineTextAlignment(.center)
                                .font(.headline)
                                .padding(.horizontal)

                            Text("“\(itemToDelete.text)”")
                                .italic()
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                                .padding(.horizontal)

                            HStack(spacing: 20) {
                                Button("Cancel") {
                                    showDeleteConfirmation = nil
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)

                                Button("Delete") {
                                    savedReframes.removeAll { $0.id == itemToDelete.id }
                                    showDeleteConfirmation = nil
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding(40)
                    }
                }

            }
        }
    }
}

struct ThoughtReframeView_Previews: PreviewProvider {
    static var previews: some View {
        ThoughtReframeView()
    }
}

#Preview {
    ThoughtReframeView()
}
