import SwiftUI

// MARK: - Safe Person Model
struct SafePerson: Identifiable {
    let id: UUID
    var name: String
    var phoneNumber: String

    init(id: UUID = UUID(), name: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

// MARK: - Checklist Item Model
struct SafetyStep: Identifiable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var isCompleted: Bool = false

    init(id: UUID = UUID(), title: String, detail: String = "", isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isCompleted = isCompleted
    }
}

// MARK: - Safety Plan Screen
struct SafetyPlanView: View {
    @State private var contacts: [SafePerson] = []
    @State private var showingAddContact = false
    @State private var editingContact: SafePerson? = nil

    @State private var safetySteps: [SafetyStep] = []
    @State private var newStepTitle = ""
    @State private var newStepDetail = ""
    @State private var editingStep: SafetyStep? = nil
    @State private var editingStepTitle = ""
    @State private var editingStepDetail = ""

    @State private var showingCallConfirmation = false
    @State private var selectedContact: SafePerson? = nil
    @State private var showingAddStepForm = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                safePersonSection
                safetyStepsSection
                notesSection
                Spacer()
            }
            .padding()
            .navigationTitle("Safety Plan")
            .sheet(isPresented: $showingAddContact) {
                AddSafePersonView { newContact in
                    contacts.append(newContact)
                }
            }
            .sheet(item: $editingContact) { contact in
                EditSafePersonView(contact: contact) { updated in
                    if let index = contacts.firstIndex(where: { $0.id == updated.id }) {
                        contacts[index] = updated
                    }
                }
            }
            .sheet(item: $editingStep) { step in
                EditSafetyStepView(step: step) { updated in
                    if let index = safetySteps.firstIndex(where: { $0.id == updated.id }) {
                        safetySteps[index] = updated
                    }
                }
            }
            .alert(isPresented: $showingCallConfirmation) {
                Alert(
                    title: Text("Call \(selectedContact?.name.isEmpty == false ? selectedContact!.name: "this contact")?"),
                    primaryButton: .default(Text("Call")) {
                        if let number = selectedContact?.phoneNumber,
                           let url = URL(string: "tel://\(number)"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Subviews

    private var safePersonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Safe People")
                .font(.headline)

            ForEach(contacts) { contact in
                HStack {
                    VStack(alignment: .leading) {
                        Text(contact.name.isEmpty ? "No Name" : contact.name)
                        Text(contact.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button {
                        selectedContact = contact
                        showingCallConfirmation = true
                    } label: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.black)
                    }
                }
                .contextMenu {
                    Button("Edit") {
                        editingContact = contact
                    }
                    Button("Delete", role: .destructive) {
                        contacts.removeAll { $0.id == contact.id }
                    }
                }
            }

            if contacts.count < 2 {
                Button("Add Safe Person") {
                    showingAddContact = true
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var safetyStepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Steps")
                .font(.headline)

            ForEach(safetySteps) { step in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button {
                            if let index = safetySteps.firstIndex(where: { $0.id == step.id }) {
                                safetySteps[index].isCompleted.toggle()
                            }
                        } label: {
                            Image(systemName: step.isCompleted ? "checkmark.circle" : "circle")
                        }
                        Text(step.title)
                    }
                    Text(step.detail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Divider()
                }
                .contextMenu {
                    Button("Edit") {
                        editingStep = step
                        editingStepTitle = step.title
                        editingStepDetail = step.detail
                    }
                    Button("Delete", role: .destructive) {
                        safetySteps.removeAll { $0.id == step.id }
                    }
                }
            }

            if showingAddStepForm {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("What to do", text: $newStepTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Details (optional)", text: $newStepDetail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Save Step") {
                        if !newStepTitle.isEmpty {
                            safetySteps.append(SafetyStep(title: newStepTitle, detail: newStepDetail))
                            newStepTitle = ""
                            newStepDetail = ""
                            showingAddStepForm = false
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Button {
                    showingAddStepForm = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add a Safety Step")
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var notesSection: some View {
        VStack {
            Text("Very Low Appreciation Daily Activity Updates Here")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Add Safe Person Sheet
struct AddSafePersonView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""

    var onSave: (SafePerson) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Name (optional)", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Safe Person")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !phone.trimmingCharacters(in: .whitespaces).isEmpty {
                            let contact = SafePerson(name: name, phoneNumber: phone)
                            onSave(contact)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Safe Person Sheet
struct EditSafePersonView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var phone: String

    var contact: SafePerson
    var onSave: (SafePerson) -> Void

    init(contact: SafePerson, onSave: @escaping (SafePerson) -> Void) {
        self.contact = contact
        self.onSave = onSave
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phoneNumber)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Name (optional)", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
            }
            .navigationTitle("Edit Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = SafePerson(id: contact.id, name: name, phoneNumber: phone)
                        onSave(updated)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Safety Step Sheet
struct EditSafetyStepView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var detail: String

    var step: SafetyStep
    var onSave: (SafetyStep) -> Void

    init(step: SafetyStep, onSave: @escaping (SafetyStep) -> Void) {
        self.step = step
        self.onSave = onSave
        _title = State(initialValue: step.title)
        _detail = State(initialValue: step.detail)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("What to do", text: $title)
                TextField("Details (optional)", text: $detail)
            }
            .navigationTitle("Edit Step")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = SafetyStep(id: step.id, title: title, detail: detail, isCompleted: step.isCompleted)
                        onSave(updated)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SafetyPlanView()
}
