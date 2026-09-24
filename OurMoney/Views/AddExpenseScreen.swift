import SwiftUI
import Combine

// MARK: - Models

// Assuming these models are defined elsewhere or in a common file
struct SplitAmount: Identifiable, Hashable {
    let id = UUID() // Unique ID for SwiftUI ForEach, if not provided by backend
    let userId: String
    let amountPaise: Int64
}

enum SplitMethod: String, CaseIterable, Identifiable {
    case equal = "EQUAL"
    // Add other methods if they exist in Kotlin
    var id: String { self.rawValue }
}

struct CustomCategory: Identifiable, Hashable {
    let id: String // Assuming an ID for deletion
    let name: String
}

// Placeholder for User model, should be defined in a common place
struct User: Identifiable {
    let id: String
    let name: String
}

// MARK: - ViewModel

class AddExpenseViewModel: ObservableObject {
    @Published var initialDataLoaded: Bool = false
    @Published var initialAmountStr: String = ""
    @Published var initialCategory: String = ""
    @Published var initialIsPersonal: Bool = false
    @Published var initialPaidByMe: Bool = true
    @Published var initialPaymentMethod: String = "UPI"
    @Published var initialNotes: String = ""
    @Published var initialDateMillis: Int64 = Date().millisecondsSince1970

    @Published var isSaving: Bool = false
    @Published var error: String? = nil
    @Published var partnerName: String = "Friend" // Default partner name
    @Published var customCategories: [CustomCategory] = []

    let currentUser = User(id: "current_user_id", name: "You") // Replace with actual user data
    let otherUserId: String // This should be passed or fetched from a repository

    private var cancellables = Set<AnyCancellable>()

    // Initialize with an optional expenseId for editing, and otherUserId for shared expenses
    init(expenseId: String? = nil, otherUserId: String = "") {
        self.otherUserId = otherUserId

        // Simulate loading initial data from a repository or API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let expenseId = expenseId {
                // Simulate loading an existing expense
                self.initialAmountStr = "150.75"
                self.initialCategory = "Food & Dining"
                self.initialIsPersonal = false
                self.initialPaidByMe = true
                self.initialPaymentMethod = "UPI"
                self.initialNotes = "Lunch with friend"
                self.initialDateMillis = Date().millisecondsSince1970 - (2 * 60 * 60 * 1000) // 2 hours ago
                self.partnerName = "Alice" // Example partner name
                self.customCategories = [CustomCategory(id: "cat1", name: "Books"), CustomCategory(id: "cat2", name: "Coffee")]
            } else {
                // Default values for a new expense
                self.initialAmountStr = ""
                self.initialCategory = "Food & Dining" // Default category
                self.initialIsPersonal = false
                self.initialPaidByMe = true
                self.initialPaymentMethod = "UPI"
                self.initialNotes = ""
                self.initialDateMillis = Date().millisecondsSince1970
                self.partnerName = "Alice" // Example partner name
                self.customCategories = [CustomCategory(id: "cat1", name: "Books"), CustomCategory(id: "cat2", name: "Coffee")]
            }
            self.initialDataLoaded = true
        }
    }

    func addCustomCategory(_ name: String) {
        // Simulate API call to add category
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newCat = CustomCategory(id: UUID().uuidString, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            self.customCategories.append(newCat)
            self.customCategories.sort { $0.name < $1.name } // Keep categories sorted
        }
    }

    func deleteCustomCategory(_ id: String) {
        // Simulate API call to delete category
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.customCategories.removeAll { $0.id == id }
        }
    }

    func saveExpense(
        amountPaise: Int64,
        category: String,
        isPersonal: Bool,
        paidByCurrentUser: Bool,
        splitMethod: SplitMethod,
        splits: [SplitAmount],
        notes: String,
        paymentMethod: String,
        dateMillis: Int64,
        onSuccess: @escaping () -> Void
    ) {
        isSaving = true
        error = nil
        // Simulate API call to save expense
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSaving = false
            if Bool.random() { // Simulate success/failure
                print("Expense saved successfully!")
                print("Amount: \(amountPaise), Category: \(category), IsPersonal: \(isPersonal), PaidByMe: \(paidByCurrentUser), Notes: \(notes), PaymentMethod: \(paymentMethod), Date: \(Date(milliseconds: dateMillis))")
                onSuccess()
            } else {
                self.error = "Failed to save expense. Please try again."
            }
        }
    }
}

// MARK: - AddExpenseScreen View

struct AddExpenseScreen: View {
    @Environment(\.dismiss) var dismiss // For programmatic dismissal of the view
    @StateObject var viewModel: AddExpenseViewModel
    let onBack: () -> Void // Closure to handle navigation back

    // Local state variables, initialized from ViewModel's initial values
    @State private var amountStr: String = ""
    @State private var category: String = ""
    @State private var isPersonal: Bool = false
    @State private var paidByMe: Bool = true
    @State private var paymentMethod: String = "UPI"
    @State private var notes: String = ""
    @State private var date: Date = Date() // Use Date directly for SwiftUI DatePicker

    @State private var showDatePickerSheet: Bool = false // Controls presentation of the date/time picker
    @State private var validationError: Bool = false

    @State private var isFormVisible: Bool = false // For entry animation

    @State private var showAddCategoryDialog: Bool = false
    @State private var newCategoryName: String = ""

    private var cancellables = Set<AnyCancellable>() // For Combine subscriptions

    init(viewModel: AddExpenseViewModel, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBack = onBack
    }

    var body: some View {
        ZStack { // Mimics Scaffold's transparent containerColor
            Color.clear.ignoresSafeArea() // Transparent background

            VStack {
                if !viewModel.initialDataLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ElevatedCardView {
                                VStack(spacing: 16) {
                                    TextField("Amount (₹)", text: $amountStr)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(viewModel.isSaving)

                                    categoryPicker

                                    paymentMethodPicker

                                    dateTimeSelectionRow

                                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(viewModel.isSaving)

                                    expenseTypeSection

                                    // Conditional text based on expense type
                                    if !isPersonal {
                                        if viewModel.otherUserId.isNotBlank {
                                            paidBySection
                                        }
                                        Text("Shared expense: Split 50/50 between both users. Affects balance settlements.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if paidByMe {
                                        Text("Personal expense for You. Only tracks your personal budget & history. Does NOT affect settlements.")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Text("Personal expense for \(viewModel.partnerName). Only tracks \(viewModel.partnerName)'s personal budget & history. Does NOT affect settlements.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(24)
                            }
                            // Animation for card entry
                            .scaleEffect(isFormVisible ? 1.0 : 0.8)
                            .opacity(isFormVisible ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: isFormVisible)

                            if validationError {
                                Text("Please enter a valid amount and category")
                                    .foregroundColor(.red)
                            }
                            if let error = viewModel.error {
                                Text(error)
                                    .foregroundColor(.red)
                            }

                            Button {
                                saveExpenseAction()
                            } label: {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                    Text("Saving...")
                                } else {
                                    Text("Save")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(height: 56)
                            .disabled(viewModel.isSaving)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8) // Adjust vertical padding for scrollview content
                    }
                    .scrollDismissesKeyboard(.interactively) // Mimics imePadding
                }
            }
            .navigationTitle("Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "arrow.backward")
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                // Subscribe to initialDataLoaded to update local state
                viewModel.$initialDataLoaded
                    .filter { $0 } // Only react when data is loaded
                    .sink { _ in
                        amountStr = viewModel.initialAmountStr
                        category = viewModel.initialCategory
                        isPersonal = viewModel.initialIsPersonal
                        paidByMe = viewModel.initialPaidByMe
                        paymentMethod = viewModel.initialPaymentMethod
                        notes = viewModel.initialNotes
                        date = Date(milliseconds: viewModel.initialDateMillis)
                        isFormVisible = true // Trigger animation after data loaded
                    }
                    .store(in: &cancellables)
            }
            // Sheet for Date and Time Picker
            .sheet(isPresented: $showDatePickerSheet) {
                VStack {
                    DatePicker(
                        "Select Date and Time",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden() // Hide default label

                    Button("Confirm") {
                        showDatePickerSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            // Alert for adding custom category
            .alert("Add Custom Category", isPresented: $showAddCategoryDialog) {
                TextField("Category Name", text: $newCategoryName)
                Button("Add") {
                    if !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.addCustomCategory(newCategoryName)
                        category = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        newCategoryName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
            } message: {
                Text("Enter a name for your new category.")
            }
        }
    }

    // MARK: - Private Helper Views

    private var categoryPicker: some View {
        Menu {
            // Combine standard and custom categories, make distinct, and sort
            ForEach((standardCategories + viewModel.customCategories.map { $0.name }).distinct().sorted(), id: \.self) { catName in
                Button {
                    category = catName
                } label: {
                    HStack {
                        Text(catName)
                        Spacer()
                        // Show delete icon only for custom categories
                        if let customCat = viewModel.customCategories.first(where: { $0.name == catName }) {
                            Button {
                                viewModel.deleteCustomCategory(customCat.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain) // Prevent button style from affecting the trash icon
                        }
                    }
                }
            }
            Divider()
            Button {
                showAddCategoryDialog = true
            } label: {
                Label("Add Custom Category...", systemImage: "plus.circle.fill")
            }
        } label: {
            HStack {
                Text(category.isEmpty ? "Select Category" : category)
                    .foregroundColor(category.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .disabled(viewModel.isSaving)
    }

    private var paymentMethodPicker: some View {
        VStack(alignment: .leading) {
            Text("Payment Method")
                .font(.subheadline)
                .fontWeight(.medium)
            HStack {
                Toggle(isOn: Binding(
                    get: { paymentMethod == "UPI" },
                    set: { if $0 { paymentMethod = "UPI" } }
                )) {
                    Text("UPI")
                }
                .toggleStyle(.radio)
                .disabled(viewModel.isSaving)

                Spacer().frame(width: 16)

                Toggle(isOn: Binding(
                    get: { paymentMethod == "Cash" },
                    set: { if $0 { paymentMethod = "Cash" } }
                )) {
                    Text("Cash")
                }
                .toggleStyle(.radio)
                .disabled(viewModel.isSaving)
            }
        }
    }

    private var dateTimeSelectionRow: some View {
        HStack {
            Text("Date & Time")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Button {
                showDatePickerSheet = true
            } label: {
                Text(date, formatter: Self.dateFormatter)
                    .foregroundColor(.accentColor)
                    .font(.body)
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.vertical, 8)
    }

    private var expenseTypeSection: some View {
        VStack(alignment: .leading) {
            Text("Expense Type")
                .font(.subheadline)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                let isSharedSelected = !isPersonal
                let isMyPersonalSelected = isPersonal && paidByMe
                let isFriendPersonalSelected = isPersonal && !paidByMe

                ExpenseTypeButton(
                    title: "Shared 50/50",
                    isSelected: isSharedSelected,
                    isDisabled: viewModel.isSaving
                ) {
                    isPersonal = false
                }

                ExpenseTypeButton(
                    title: "My Personal",
                    isSelected: isMyPersonalSelected,
                    isDisabled: viewModel.isSaving
                ) {
                    isPersonal = true
                    paidByMe = true
                }

                if viewModel.otherUserId.isNotBlank {
                    ExpenseTypeButton(
                        title: viewModel.partnerName.isNotBlank && viewModel.partnerName != "Friend" ? "\(viewModel.partnerName.prefix(8))'s" : "Friend's",
                        isSelected: isFriendPersonalSelected,
                        isDisabled: viewModel.isSaving
                    ) {
                        isPersonal = true
                        paidByMe = false
                    }
                }
            }
            .background(Color.secondary.opacity(0.1).cornerRadius(14)) // Mimics background with RoundedCornerShape
        }
    }

    private var paidBySection: some View {
        VStack(alignment: .leading) {
            Text("Paid By")
                .font(.subheadline)
                .fontWeight(.medium)
            HStack {
                Toggle(isOn: Binding(
                    get: { paidByMe },
                    set: { paidByMe = $0 }
                )) {
                    Text("You")
                }
                .toggleStyle(.radio)
                .disabled(viewModel.isSaving)

                Spacer().frame(width: 16)

                Toggle(isOn: Binding(
                    get: { !paidByMe },
                    set: { paidByMe = !$0 }
                )) {
                    Text(viewModel.partnerName)
                }
                .toggleStyle(.radio)
                .disabled(viewModel.isSaving)
            }
        }
    }

    // MARK: - Action Methods

    private func saveExpenseAction() {
        let amount = Double(amountStr)
        if let amount = amount, amount > 0, !category.isEmpty {
            validationError = false
            let amountPaise = (amount * 100).toLong()

            var splits: [SplitAmount] = []
            if isPersonal {
                if paidByMe {
                    splits = [SplitAmount(userId: viewModel.currentUser.id, amountPaise: amountPaise)]
                } else {
                    splits = [SplitAmount(userId: viewModel.otherUserId, amountPaise: amountPaise)]
                }
            } else if viewModel.otherUserId.isEmpty {
                // If no other user, shared expense is effectively personal for current user
                splits = [SplitAmount(userId: viewModel.currentUser.id, amountPaise: amountPaise)]
            } else {
                let half = amountPaise / 2
                let otherHalf = amountPaise - half
                splits = [
                    SplitAmount(userId: viewModel.currentUser.id, amountPaise: half),
                    SplitAmount(userId: viewModel.otherUserId, amountPaise: otherHalf)
                ]
            }

            viewModel.saveExpense(
                amountPaise: amountPaise,
                category: category,
                isPersonal: isPersonal,
                paidByCurrentUser: paidByMe,
                splitMethod: .equal, // Assuming EQUAL for now as per Compose code
                splits: splits,
                notes: notes,
                paymentMethod: paymentMethod,
                dateMillis: date.millisecondsSince1970,
                onSuccess: onBack
            )
        } else {
            validationError = true
        }
    }

    // MARK: - Static Properties & Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        return formatter
    }()

    private let standardCategories = ["Food & Dining", "Groceries", "Transport", "Shopping", "Entertainment", "Bills & Utilities", "Health", "Travel", "Education", "Misc"]
}

// MARK: - Helper Views

// Mimics Compose's ElevatedCard
struct ElevatedCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.secondary.opacity(0.1)) // Mimics MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: 0) // Mimics defaultElevation = 0.dp
            )
    }
}

// Helper for the segmented expense type buttons
struct ExpenseTypeButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .disabled(isDisabled)
    }
}

// MARK: - Extensions

extension String {
    var isNotBlank: Bool {
        !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Int64 {
    func toDouble() -> Double {
        Double(self)
    }
}

extension Double {
    func toLong() -> Int64 {
        Int64(self.rounded())
    }
}

extension Array where Element: Hashable {
    func distinct() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// Custom ToggleStyle to mimic Material Design RadioButton
struct RadioToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(configuration.isOn ? .accentColor : .gray)
                configuration.label
            }
        }
        .buttonStyle(.plain) // Ensure the button itself doesn't get default styling
    }
}

extension ToggleStyle where Self == RadioToggleStyle {
    static var radio: RadioToggleStyle {
        RadioToggleStyle()
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}