import SwiftUI
import Combine
import CoreMotion // For MotionGestureEngine
import UserNotifications // For AquaDynamicsNotificationHelper

// MARK: - Data Models
// These models are assumed to be defined elsewhere in a real application.
// For the purpose of this conversion, minimal definitions are provided.

struct User: Identifiable, Hashable {
    let id: String
    let name: String
    // Add other properties as needed
}

struct Household: Identifiable, Hashable {
    let id: String
    let members: [String] // User IDs
    // Add other properties as needed
}

struct Transaction: Identifiable, Hashable {
    let id: String
    let paidBy: String
    let createdBy: String
    let amountPaise: Int
    let category: String
    let notes: String
    let personal: Bool
    // Add other properties as needed
}

struct Settlement: Identifiable, Hashable {
    let id: String
    // Add other properties as needed
}

struct PartnerDropData: Hashable {
    let partnerName: String
    let amount: Double
    let category: String
    let note: String
    let isShared: Bool
    let transactionId: String
}

// MARK: - Repositories

class UserRepository {
    func getUserSuspend(_ userId: String) async -> User? {
        // Simulate network/database call
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        if userId == "partner123" { // Example partner ID
            return User(id: userId, name: "Khushal")
        }
        return nil
    }
}

class LedgerRepository {
    private let householdId: String
    private let userId: String
    private let transactionsSubject = PassthroughSubject<[Transaction], Never>()
    private var timer: AnyCancellable?
    private var currentTransactions: [Transaction] = []

    init(householdId: String, userId: String) {
        self.householdId = householdId
        self.userId = userId
        // Simulate real-time updates
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.simulateNewTransaction()
            }
        // Initial data
        currentTransactions = [
            Transaction(id: "tx1", paidBy: "user1", createdBy: "user1", amountPaise: 1500, category: "Groceries", notes: "Weekly shop", personal: false),
            Transaction(id: "tx2", paidBy: "user2", createdBy: "user2", amountPaise: 2500, category: "Dinner", notes: "Restaurant", personal: false)
        ]
        transactionsSubject.send(currentTransactions)
    }

    deinit {
        timer?.cancel()
    }

    func getTransactions() -> AnyPublisher<[Transaction], Never> {
        return transactionsSubject.eraseToAnyPublisher()
    }

    private func simulateNewTransaction() {
        // Simulate a new transaction from partner
        let newTxId = "tx\(currentTransactions.count + 1)"
        let newTransaction = Transaction(
            id: newTxId,
            paidBy: "partner123", // Assuming partner123 is the other user
            createdBy: "partner123",
            amountPaise: Int.random(in: 500...5000),
            category: ["Food & Dining", "Transport", "Entertainment", "Utilities"].randomElement()!,
            notes: "Simulated partner expense",
            personal: Bool.random()
        )
        currentTransactions.append(newTransaction)
        transactionsSubject.send(currentTransactions)
    }
}

// MARK: - Motion & Settings

class MotionSettingsManager: ObservableObject {
    @Published var motionQuickAddEnabled: Bool = UserDefaults.standard.bool(forKey: "motionQuickAddEnabled") {
        didSet { UserDefaults.standard.set(motionQuickAddEnabled, forKey: "motionQuickAddEnabled") }
    }
    @Published var shakeToAddEnabled: Bool = UserDefaults.standard.bool(forKey: "shakeToAddEnabled") {
        didSet { UserDefaults.standard.set(shakeToAddEnabled, forKey: "shakeToAddEnabled") }
    }
    @Published var backgroundServiceEnabled: Bool = UserDefaults.standard.bool(forKey: "backgroundServiceEnabled") {
        didSet { UserDefaults.standard.set(backgroundServiceEnabled, forKey: "backgroundServiceEnabled") }
    }

    init() {
        // Set default values if not present
        if UserDefaults.standard.object(forKey: "motionQuickAddEnabled") == nil {
            motionQuickAddEnabled = true
        }
        if UserDefaults.standard.object(forKey: "shakeToAddEnabled") == nil {
            shakeToAddEnabled = true
        }
        if UserDefaults.standard.object(forKey: "backgroundServiceEnabled") == nil {
            backgroundServiceEnabled = false // iOS background services are different and restricted
        }
    }

    func saveHouseholdContext(householdId: String, userId: String, userName: String, partnerId: String, partnerName: String) {
        UserDefaults.standard.set(householdId, forKey: "householdId")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(partnerId, forKey: "partnerId")
        UserDefaults.standard.set(partnerName, forKey: "partnerName")
    }
}

class MotionGestureEngine: ObservableObject {
    private let motionManager = CMMotionManager()
    let events = PassthroughSubject<Void, Never>()
    private let settingsManager: MotionSettingsManager
    private var shakeCount = 0
    private let shakeThreshold: Double = 2.5 // g's
    private let shakeWindow: TimeInterval = 0.5 // seconds
    private var lastShakeTime: Date?

    init(settingsManager: MotionSettingsManager) {
        self.settingsManager = settingsManager
    }

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer is not available")
            return
        }

        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let acceleration = data?.acceleration else { return }

            let x = acceleration.x
            let y = acceleration.y
            let z = acceleration.z

            let magnitude = sqrt(x*x + y*y + z*z)
            if magnitude > self.shakeThreshold {
                let now = Date()
                if let lastTime = self.lastShakeTime, now.timeIntervalSince(lastTime) < self.shakeWindow {
                    self.shakeCount += 1
                } else {
                    self.shakeCount = 1
                }
                self.lastShakeTime = now

                if self.shakeCount >= 2 { // Detect a quick double shake
                    self.events.send(())
                    self.shakeCount = 0 // Reset after detection
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}

class AquaDynamicsNotificationHelper {
    static func showExpenseSavedNotification(context: Any?, amount: Double, category: String, isShared: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Expense Saved!"
        content.body = "You saved \(String(format: "%.2f", amount)) for \(category). \(isShared ? "It's shared!" : "It's personal.")"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Quick Add

class QuickAddController: ObservableObject {
    @Published var isQuickAddActive: Bool = false
    @Published var partnerDropData: PartnerDropData? = nil
    private var cancellables = Set<AnyCancellable>()
    private let settingsManager: MotionSettingsManager

    init(settingsManager: MotionSettingsManager) {
        self.settingsManager = settingsManager
    }

    func triggerShake() {
        if settingsManager.motionQuickAddEnabled && settingsManager.shakeToAddEnabled {
            print("Shake detected, triggering Quick Add!")
            isQuickAddActive = true
            // Optionally, dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.isQuickAddActive = false
            }
        }
    }

    func triggerPartnerDrop(_ data: PartnerDropData) {
        print("Partner drop detected: \(data.partnerName) - \(data.amount)")
        partnerDropData = data
        isQuickAddActive = true // Activate the island to show partner drop
        // Optionally, dismiss after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.isQuickAddActive = false
            self?.partnerDropData = nil // Clear partner data after display
        }
    }

    func dismissQuickAdd() {
        isQuickAddActive = false
        partnerDropData = nil
    }
}

// MARK: - UI Components

struct AnimatedBackground: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

struct CameraAnchoredDynamicIsland: View {
    @ObservedObject var controller: QuickAddController
    var cutoutGeometry: CGRect // Simplified, in real app this would be calculated
    let householdId: String
    let userId: String
    let partnerId: String
    let partnerName: String
    let onExpenseSaved: (Double, String, Bool) -> Void

    @State private var amount: String = ""
    @State private var category: String = "Food & Dining"
    @State private var isShared: Bool = false

    var body: some View {
        Group {
            if controller.isQuickAddActive {
                VStack {
                    if let partnerDrop = controller.partnerDropData {
                        PartnerDropView(data: partnerDrop)
                            .padding()
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        QuickAddExpenseView(
                            amount: $amount,
                            category: $category,
                            isShared: $isShared,
                            onSave: {
                                onExpenseSaved(Double(amount) ?? 0.0, category, isShared)
                                controller.dismissQuickAdd()
                            },
                            onDismiss: {
                                controller.dismissQuickAdd()
                            }
                        )
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, cutoutGeometry.maxY + 10) // Position below cutout
            }
        }
        .animation(.spring(), value: controller.isQuickAddActive)
    }
}

struct PartnerDropView: View {
    let data: PartnerDropData

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                Text("\(data.partnerName) added an expense!")
                    .font(.headline)
            }
            Text("Amount: \(String(format: "%.2f", data.amount))")
            Text("Category: \(data.category)")
            if !data.note.isEmpty {
                Text("Note: \(data.note)")
            }
            Text(data.isShared ? "Shared expense" : "Personal expense")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickAddExpenseView: View {
    @Binding var amount: String
    @Binding var category: String
    @Binding var isShared: Bool
    let onSave: () -> Void
    let onDismiss: () -> Void

    let categories = ["Food & Dining", "Transport", "Entertainment", "Utilities", "Shopping", "Rent"]

    var body: some View {
        VStack {
            HStack {
                Text("Quick Add Expense")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            Divider()
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat).tag(cat)
                }
            }
            .pickerStyle(.menu)
            Toggle("Shared Expense", isOn: $isShared)
            Button("Save", action: onSave)
                .buttonStyle(.borderedProminent)
        }
    }
}

// Simplified cutout geometry for demonstration
func rememberCutoutGeometry() -> CGRect {
    // In a real app, this would use safeAreaInsets or specific device knowledge.
    // For now, a fixed value for demonstration.
    return CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
}

// MARK: - ViewModels

class DashboardViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var dashboardData: String = "Loading Dashboard..."

    init(user: User, household: Household) {
        self.user = user
        self.household = household
        loadData()
    }

    func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dashboardData = "Welcome, \(self.user.name)! Your household: \(self.household.id)"
        }
    }
}

class HistoryViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var historyItems: [String] = ["Item 1", "Item 2"]

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

class AnalyticsViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var analyticsData: String = "Analytics insights..."

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

class GoalsViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var goals: [String] = ["Goal 1", "Goal 2"]

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

class BudgetsViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var budgets: [String] = ["Budget 1", "Budget 2"]

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

class AddExpenseViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var amount: String = ""
    @Published var category: String = "Food"
    @Published var notes: String = ""
    @Published var isEditing: Bool = false
    @Published var transactionId: String?

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }

    func setModeCreate() {
        isEditing = false
        transactionId = nil
        amount = ""
        category = "Food"
        notes = ""
    }

    func loadTransaction(_ id: String) {
        isEditing = true
        transactionId = id
        // Simulate loading transaction data
        amount = "123.45"
        category = "Groceries"
        notes = "Editing transaction \(id)"
    }

    func saveExpense() {
        print("Saving expense: \(amount), \(category), \(notes)")
        // Logic to save/update expense
    }
}

class SettleUpViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var settlementAmount: String = ""
    @Published var isEditing: Bool = false
    @Published var settlementId: String?

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }

    func setModeCreate() {
        isEditing = false
        settlementId = nil
        settlementAmount = ""
    }

    func loadSettlement(_ id: String) {
        isEditing = true
        settlementId = id
        // Simulate loading settlement data
        settlementAmount = "50.00"
    }

    func saveSettlement() {
        print("Saving settlement: \(settlementAmount)")
        // Logic to save/update settlement
    }
}

class SettingsViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var setting1: Bool = false
    @Published var setting2: String = "Option A"

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

class AiViewModel: ObservableObject {
    let user: User
    let household: Household
    @Published var aiResponse: String = "AI is thinking..."

    init(user: User, household: Household) {
        self.user = user
        self.household = household
    }
}

// MARK: - Screens

struct DashboardScreen: View {
    @StateObject var viewModel: DashboardViewModel
    let onAddExpense: () -> Void
    let onEditExpense: (String) -> Void
    let onSettleUp: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack {
            Text(viewModel.dashboardData)
                .font(.title)
                .padding()
            Button("Add Expense", action: onAddExpense)
            Button("Settle Up", action: onSettleUp)
            Button("Settings", action: onSettings)
            Button("Edit Expense (Example)", action: { onEditExpense("exampleTxId") })
        }
        .navigationTitle("Dashboard")
    }
}

struct HistoryScreen: View {
    @StateObject var viewModel: HistoryViewModel
    let onEditExpense: (String) -> Void
    let onEditSettlement: (String) -> Void

    var body: some View {
        VStack {
            Text("History Screen")
            ForEach(viewModel.historyItems, id: \.self) { item in
                Text(item)
            }
            Button("Edit Expense (Example)", action: { onEditExpense("exampleTxId") })
            Button("Edit Settlement (Example)", action: { onEditSettlement("exampleSettlementId") })
        }
        .navigationTitle("History")
    }
}

struct AnalyticsScreen: View {
    @StateObject var viewModel: AnalyticsViewModel

    var body: some View {
        VStack {
            Text("Analytics Screen")
            Text(viewModel.analyticsData)
        }
        .navigationTitle("Analytics")
    }
}

struct GoalsScreen: View {
    @StateObject var viewModel: GoalsViewModel

    var body: some View {
        VStack {
            Text("Goals Screen")
            ForEach(viewModel.goals, id: \.self) { goal in
                Text(goal)
            }
        }
        .navigationTitle("Goals")
    }
}

struct BudgetsScreen: View {
    @StateObject var viewModel: BudgetsViewModel

    var body: some View {
        VStack {
            Text("Budgets Screen")
            ForEach(viewModel.budgets, id: \.self) { budget in
                Text(budget)
            }
        }
        .navigationTitle("Budgets")
    }
}

struct AddExpenseScreen: View {
    @StateObject var viewModel: AddExpenseViewModel
    let onBack: () -> Void

    var body: some View {
        VStack {
            Text(viewModel.isEditing ? "Edit Expense" : "Add New Expense")
                .font(.title)
            TextField("Amount", text: $viewModel.amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("Category", text: $viewModel.category)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("Notes", text: $viewModel.notes)
                .textFieldStyle(.roundedBorder)
                .padding()
            Button("Save", action: {
                viewModel.saveExpense()
                onBack()
            })
            .buttonStyle(.borderedProminent)
            Button("Cancel", action: onBack)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Expense" : "Add Expense")
    }
}

struct SettleUpScreen: View {
    @StateObject var viewModel: SettleUpViewModel
    let onBack: () -> Void

    var body: some View {
        VStack {
            Text(viewModel.isEditing ? "Edit Settlement" : "Settle Up")
                .font(.title)
            TextField("Amount", text: $viewModel.settlementAmount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .padding()
            Button("Save", action: {
                viewModel.saveSettlement()
                onBack()
            })
            .buttonStyle(.borderedProminent)
            Button("Cancel", action: onBack)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Settlement" : "Settle Up")
    }
}

struct SettingsScreen: View {
    @StateObject var viewModel: SettingsViewModel
    @ObservedObject var settingsManager: MotionSettingsManager
    let onBack: () -> Void

    var body: some View {
        VStack {
            Text("Settings Screen")
                .font(.title)
            Toggle("Motion Quick Add Enabled", isOn: $settingsManager.motionQuickAddEnabled)
                .padding()
            Toggle("Shake to Add Enabled", isOn: $settingsManager.shakeToAddEnabled)
                .padding()
            Toggle("Background Service Enabled (iOS: Limited)", isOn: $settingsManager.backgroundServiceEnabled)
                .padding()
            Button("Back", action: onBack)
        }
        .navigationTitle("Settings")
    }
}

struct AiScreen: View {
    @StateObject var viewModel: AiViewModel

    var body: some View {
        VStack {
            Text("AI Screen")
            Text(viewModel.aiResponse)
        }
        .navigationTitle("AI Assistant")
    }
}

// MARK: - MainScreen Conversion

struct MainScreen: View {
    let user: User
    let household: Household

    @State private var path = NavigationPath()
    @StateObject private var settingsManager = MotionSettingsManager()
    @StateObject private var quickAddController: QuickAddController
    @StateObject private var motionGestureEngine: MotionGestureEngine

    @State private var otherUserId: String = ""
    @State private var partnerName: String = "Partner"
    @State private var knownTransactionIds: Set<String>? = nil

    private let userRepository = UserRepository()
    private let ledgerRepository: LedgerRepository

    init(user: User, household: Household) {
        self.user = user
        self.household = household
        _settingsManager = StateObject(wrappedValue: MotionSettingsManager())
        _quickAddController = StateObject(wrappedValue: QuickAddController(settingsManager: _settingsManager.wrappedValue))
        _motionGestureEngine = StateObject(wrappedValue: MotionGestureEngine(settingsManager: _settingsManager.wrappedValue))
        self.ledgerRepository = LedgerRepository(householdId: household.id, userId: user.id)
    }

    // Define navigation routes
    enum Route: Hashable {
        case dashboard
        case history
        case analytics
        case goals
        case budgets
        case ai
        case addExpense
        case editExpense(transactionId: String)
        case settleUp
        case editSettlement(settlementId: String)
        case settings
    }

    var body: some View {
        ZStack {
            AnimatedBackground()

            NavigationStack(path: $path) {
                DashboardScreen(
                    viewModel: DashboardViewModel(user: user, household: household),
                    onAddExpense: { path.append(Route.addExpense) },
                    onEditExpense: { id in path.append(Route.editExpense(transactionId: id)) },
                    onSettleUp: { path.append(Route.settleUp) },
                    onSettings: { path.append(Route.settings) }
                )
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .dashboard:
                        DashboardScreen(
                            viewModel: DashboardViewModel(user: user, household: household),
                            onAddExpense: { path.append(Route.addExpense) },
                            onEditExpense: { id in path.append(Route.editExpense(transactionId: id)) },
                            onSettleUp: { path.append(Route.settleUp) },
                            onSettings: { path.append(Route.settings) }
                        )
                    case .history:
                        HistoryScreen(
                            viewModel: HistoryViewModel(user: user, household: household),
                            onEditExpense: { id in path.append(Route.editExpense(transactionId: id)) },
                            onEditSettlement: { id in path.append(Route.editSettlement(settlementId: id)) }
                        )
                    case .analytics:
                        AnalyticsScreen(viewModel: AnalyticsViewModel(user: user, household: household))
                    case .goals:
                        GoalsScreen(viewModel: GoalsViewModel(user: user, household: household))
                    case .budgets:
                        BudgetsScreen(viewModel: BudgetsViewModel(user: user, household: household))
                    case .ai:
                        AiScreen(viewModel: AiViewModel(user: user, household: household))
                    case .addExpense:
                        AddExpenseScreen(
                            viewModel: {
                                let vm = AddExpenseViewModel(user: user, household: household)
                                vm.setModeCreate()
                                return vm
                            }(),
                            onBack: { path.removeLast() }
                        )
                    case .editExpense(let transactionId):
                        AddExpenseScreen(
                            viewModel: {
                                let vm = AddExpenseViewModel(user: user, household: household)
                                vm.loadTransaction(transactionId)
                                return vm
                            }(),
                            onBack: { path.removeLast() }
                        )
                    case .settleUp:
                        SettleUpScreen(
                            viewModel: {
                                let vm = SettleUpViewModel(user: user, household: household)
                                vm.setModeCreate()
                                return vm
                            }(),
                            onBack: { path.removeLast() }
                        )
                    case .editSettlement(let settlementId):
                        SettleUpScreen(
                            viewModel: {
                                let vm = SettleUpViewModel(user: user, household: household)
                                vm.loadSettlement(settlementId)
                                return vm
                            }(),
                            onBack: { path.removeLast() }
                        )
                    case .settings:
                        SettingsScreen(
                            viewModel: SettingsViewModel(user: user, household: household),
                            settingsManager: settingsManager,
                            onBack: { path.removeLast() }
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Spacer()
                            bottomBarItem(icon: "house.fill", label: "Home", route: .dashboard)
                            Spacer()
                            bottomBarItem(icon: "list.bullet.rectangle.portrait.fill", label: "History", route: .history)
                            Spacer()
                            bottomBarItem(icon: "star.fill", label: "Stats", route: .analytics)
                            Spacer()
                            bottomBarItem(icon: "dollarsign.circle.fill", label: "Budgets", route: .budgets) // Changed icon from checkmark.circle.fill
                            Spacer()
                            bottomBarItem(icon: "target", label: "Goals", route: .goals) // Changed icon from checkmark.circle.fill
                            Spacer()
                            bottomBarItem(icon: "sparkles", label: "AI", route: .ai)
                            Spacer()
                        }
                        .background(Material.ultraThinMaterial)
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // Camera Cutout Anchored Dynamic Island
            CameraAnchoredDynamicIsland(
                controller: quickAddController,
                cutoutGeometry: rememberCutoutGeometry(),
                householdId: household.id,
                userId: user.id,
                partnerId: otherUserId,
                partnerName: partnerName,
                onExpenseSaved: { amount, category, isShared in
                    AquaDynamicsNotificationHelper.showExpenseSavedNotification(
                        context: nil,
                        amount: amount,
                        category: category,
                        isShared: isShared
                    )
                }
            )
        }
        .onAppear {
            // Initialize otherUserId
            otherUserId = household.members.first { $0 != user.id } ?? ""

            // Start MotionGestureEngine if enabled
            if settingsManager.motionQuickAddEnabled && settingsManager.shakeToAddEnabled {
                motionGestureEngine.start()
            }
        }
        .onDisappear {
            motionGestureEngine.stop()
        }
        .onChange(of: settingsManager.motionQuickAddEnabled) { newValue in
            if newValue && settingsManager.shakeToAddEnabled { motionGestureEngine.start() } else { motionGestureEngine.stop() }
        }
        .onChange(of: settingsManager.shakeToAddEnabled) { newValue in
            if newValue && settingsManager.motionQuickAddEnabled { motionGestureEngine.start() } else { motionGestureEngine.stop() }
        }
        .onChange(of: otherUserId) { newOtherUserId in
            Task {
                if newOtherUserId.isNotBlank() {
                    if let partner = await userRepository.getUserSuspend(newOtherUserId) {
                        if partner.name.isNotBlank() {
                            partnerName = partner.name
                        }
                    }
                }
                // Cache household & partner context
                settingsManager.saveHouseholdContext(
                    householdId: household.id,
                    userId: user.id,
                    userName: user.name,
                    partnerId: newOtherUserId,
                    partnerName: partnerName
                )
            }
        }
        .onReceive(motionGestureEngine.events) { _ in
            quickAddController.triggerShake()
        }
        .onReceive(ledgerRepository.getTransactions()) { transactions in
            if knownTransactionIds == nil {
                knownTransactionIds = Set(transactions.map { $0.id })
            } else {
                let newPartnerTx = transactions.first { tx in
                    !(knownTransactionIds?.contains(tx.id) ?? false) &&
                    tx.paidBy != user.id &&
                    (tx.createdBy != user.id || tx.paidBy.isNotBlank())
                }
                if let newTx = newPartnerTx {
                    let cleanPartnerName = (partnerName.isNotBlank() && partnerName != "Partner") ? partnerName : "Khushal"
                    quickAddController.triggerPartnerDrop(
                        PartnerDropData(
                            partnerName: cleanPartnerName,
                            amount: Double(newTx.amountPaise) / 100.0,
                            category: newTx.category.isNotBlank() ? newTx.category : "Food & Dining",
                            note: newTx.notes,
                            isShared: !newTx.personal,
                            transactionId: newTx.id
                        )
                    )
                }
                knownTransactionIds = Set(transactions.map { $0.id })
            }
        }
    }

    @ViewBuilder
    private func bottomBarItem(icon: String, label: String, route: Route) -> some View {
        Button(action: {
            // Clear path and navigate to root of the selected tab
            path = NavigationPath()
            path.append(route)
        }) {
            VStack {
                Image(systemName: icon)
                Text(label)
                    .lineLimit(1)
            }
            .foregroundColor(path.contains(route) ? .accentColor : .secondary)
        }
    }
}

// Helper extension for String.isNotBlank()
extension String {
    func isNotBlank() -> Bool {
        !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// Helper for NavigationPath to check if it contains a route
extension NavigationPath {
    func contains<T: Hashable>(_ route: T) -> Bool {
        for element in self {
            if let typedElement = element as? T, typedElement == route {
                return true
            }
        }
        return false
    }
}