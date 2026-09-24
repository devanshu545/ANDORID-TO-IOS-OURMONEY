import Foundation
import Combine
import SwiftUI

// MARK: - Data Models (Assumed to be defined elsewhere, included here for completeness)

/// Extension to allow initializing SwiftUI Color from a hex UInt.
extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

/// Custom colors to simulate MaterialTheme.colorScheme.
extension Color {
    static let primaryColor = Color(hex: 0xFF6200EA)
    static let primaryContainer = Color.primaryColor.opacity(0.2)
    static let secondaryContainer = Color(hex: 0xFF03DAC5).opacity(0.2)
    static let tertiaryContainer = Color(hex: 0xFFFF0266).opacity(0.2)
    static let errorContainer = Color.red.opacity(0.2)
    static let onErrorContainer = Color.red
    static let onSurfaceVariant = Color.gray
    static let onSurface = Color.primary
}

/// Represents a user in the system.
struct User: Identifiable, Hashable {
    let id: String
    let name: String
    // Add other user-specific properties as needed
}

/// Represents a household.
struct Household: Identifiable, Hashable {
    let id: String
    let name: String
    // Add other household-specific properties as needed
}

/// Defines the type of a financial transaction.
enum TransactionType: String, Codable, CaseIterable {
    case EXPENSE
    case INCOME
    case TRANSFER
}

/// Represents a single financial transaction.
struct Transaction: Identifiable, Hashable {
    let id: String
    let amountPaise: Int // Amount in the smallest currency unit (e.g., paise for INR)
    let type: TransactionType
    let category: String
    let paymentMethod: String
    let paidBy: String // User ID of the person who paid
    let notes: String
    let isDeleted: Bool
    let timestamp: Date // Date of the transaction
    // Add other transaction-specific properties as needed
}

/// Extension for String to check if it contains non-whitespace characters.
extension String {
    var isNotBlank: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Extension for Sequence of Transactions to sum a specific Int property.
extension Sequence where Element == Transaction {
    func sumOf(_ keyPath: KeyPath<Element, Int>) -> Int {
        self.reduce(0) { $0 + $1[keyPath: keyPath] }
    }
}

// MARK: - LedgerRepository (Assumed to be defined elsewhere, returning Combine Publisher)

/// A repository for managing financial transactions.
class LedgerRepository {
    let householdId: String
    let currentUserId: String

    init(householdId: String, currentUserId: String) {
        self.householdId = householdId
        self.currentUserId = currentUserId
    }

    /// Returns a publisher for a list of transactions.
    /// This is a mock implementation. In a real application, this would fetch data from a backend or local database.
    func getTransactions() -> AnyPublisher<[Transaction], Never> {
        Just([
            Transaction(id: UUID().uuidString, amountPaise: 5000, type: .EXPENSE, category: "Groceries", paymentMethod: "UPI", paidBy: "user1", notes: "Weekly shopping", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 5)),
            Transaction(id: UUID().uuidString, amountPaise: 2500, type: .EXPENSE, category: "Transport", paymentMethod: "Cash", paidBy: "user1", notes: "Bus fare", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 4)),
            Transaction(id: UUID().uuidString, amountPaise: 12000, type: .EXPENSE, category: "Rent", paymentMethod: "UPI", paidBy: "user2", notes: "Monthly rent", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 3)),
            Transaction(id: UUID().uuidString, amountPaise: 1500, type: .EXPENSE, category: "Food", paymentMethod: "UPI", paidBy: "user1", notes: "Lunch", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 2)),
            Transaction(id: UUID().uuidString, amountPaise: 800, type: .EXPENSE, category: "Groceries", paymentMethod: "Cash", paidBy: "user2", notes: "Milk", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 1)),
            Transaction(id: UUID().uuidString, amountPaise: 7000, type: .INCOME, category: "Salary", paymentMethod: "Bank", paidBy: "user1", notes: "Part-time job", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 6)),
            Transaction(id: UUID().uuidString, amountPaise: 3000, type: .EXPENSE, category: "Entertainment", paymentMethod: "UPI", paidBy: "user1", notes: "Movie tickets", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 0.5)),
            Transaction(id: UUID().uuidString, amountPaise: 600, type: .EXPENSE, category: "Transport", paymentMethod: "Cash", paidBy: "user2", notes: "Taxi", isDeleted: false, timestamp: Date().addingTimeInterval(-86400 * 0.2)),
            Transaction(id: UUID().uuidString, amountPaise: 1000, type: .EXPENSE, category: "Food", paymentMethod: "UPI", paidBy: "user2", notes: "Dinner", isDeleted: false, timestamp: Date())
        ])
        .delay(for: .seconds(0.5), scheduler: DispatchQueue.main) // Simulate network delay
        .eraseToAnyPublisher()
    }
}

// MARK: - AnalyticsViewModel

/// ViewModel for the AnalyticsScreen, responsible for providing analytics data.
class AnalyticsViewModel: ObservableObject {
    let currentUser: User
    let household: Household
    private let ledgerRepository: LedgerRepository
    private var cancellables = Set<AnyCancellable>()

    @Published var transactions: [Transaction] = []

    init(currentUser: User, household: Household) {
        self.currentUser = currentUser
        self.household = household
        self.ledgerRepository = LedgerRepository(householdId: household.id, currentUserId: currentUser.id)

        // Subscribe to transactions from the repository and update the @Published property
        ledgerRepository.getTransactions()
            .receive(on: DispatchQueue.main) // Ensure updates are on the main thread
            .sink { [weak self] newTransactions in
                self?.transactions = newTransactions
            }
            .store(in: &cancellables)
    }
}

// MARK: - AnalyticsScreen Components

/// A reusable card view for displaying analytics data.
struct CardView<Content: View>: View {
    var backgroundColor: Color = Color.white // Default card background
    let content: Content

    init(backgroundColor: Color = Color.white, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

/// A row displaying category breakdown with a progress bar.
struct CategoryBreakdownRow: View {
    let category: String
    let amount: Int
    let percentage: Double
    let showContent: Bool
    let index: Int

    @State private var animatedPercentage: Double = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("₹\(Double(amount) / 100.0, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            // LinearProgressIndicator equivalent
            ProgressView(value: animatedPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryColor))
                .frame(height: 8)
                .background(Color.primaryContainer)
                .cornerRadius(4)
        }
        .onAppear {
            // Delay animation based on index for staggered effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(index) * 0.1) {
                withAnimation(.easeOut(duration: 1.0)) { // Corresponds to tween(1000)
                    if showContent {
                        animatedPercentage = percentage
                    } else {
                        animatedPercentage = 0.0
                    }
                }
            }
        }
    }
}

/// A custom Donut Chart view.
struct DonutChart: View {
    let data: [(String, Int)]
    let total: Int
    let colors: [Color] = [
        Color(hex: 0xFF6200EA),
        Color(hex: 0xFF03DAC5),
        Color(hex: 0xFFFF0266),
        Color(hex: 0xFFFFDE03),
        Color(hex: 0xFF00C853),
        Color(hex: 0xFFFF9800),
        Color(hex: 0xFF2962FF)
    ]

    @State private var animationPlayed = false
    @State private var animateSweep: Double = 0.0 // Controls the sweep animation

    var body: some View {
        ZStack {
            if total > 0 && !data.isEmpty {
                Canvas { context, size in
                    let radius = min(size.width, size.height) / 2
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let strokeWidth: CGFloat = 50

                    var startAngle: Angle = .degrees(-90)
                    for (index, (_, amount)) in data.enumerated() {
                        let sweepAngleDegrees = (Double(amount) / Double(total)) * 360.0
                        let gapDegrees: Double = data.count > 1 ? 2.0 : 0.0 // Gap between slices
                        let actualSweepDegrees = max(0.1, sweepAngleDegrees - gapDegrees) // Ensure minimum sweep

                        let endAngle = startAngle + .degrees(actualSweepDegrees * animateSweep)

                        var path = Path()
                        path.addArc(center: center,
                                    radius: radius - strokeWidth / 2,
                                    startAngle: startAngle + .degrees(gapDegrees / 2),
                                    endAngle: endAngle,
                                    clockwise: false)

                        context.stroke(path,
                                       with: .color(colors[index % colors.count]),
                                       style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))

                        startAngle += .degrees(sweepAngleDegrees)
                    }
                }
                .frame(width: 180, height: 180)
            } else {
                // Draw a gray circle if no data
                Canvas { context, size in
                    let radius = min(size.width, size.height) / 2
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let strokeWidth: CGFloat = 50

                    var path = Path()
                    path.addArc(center: center,
                                radius: radius - strokeWidth / 2,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(-90 + 360 * animateSweep),
                                clockwise: false)

                    context.stroke(path,
                                   with: .color(Color.gray.opacity(0.3)),
                                   style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                }
                .frame(width: 180, height: 180)
            }

            VStack {
                Text("Total Spent")
                    .font(.caption) // labelLarge
                    .foregroundColor(.onSurfaceVariant)
                Spacer().frame(height: 4)
                Text("₹\(Double(total) / 100.0, specifier: "%.2f")")
                    .font(.title2) // headlineMedium
                    .fontWeight(.bold)
                    .foregroundColor(.onSurface)
            }
        }
        .frame(maxWidth: .infinity) // fillMaxWidth
        .frame(height: 240) // height(240.dp)
        .onAppear {
            // Trigger animation on appear
            withAnimation(.easeOut(duration: 1.5)) { // Corresponds to tween(durationMillis = 1500, easing = LinearOutSlowInEasing)
                animationPlayed = true
                animateSweep = 1.0
            }
        }
    }
}

// MARK: - AnalyticsScreen

/// The main Analytics screen displaying financial insights.
struct AnalyticsScreen: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var showContent = false // Controls the staggered entry animations

    // Computed properties for analytics data, derived from viewModel.transactions
    private var activeTx: [Transaction] {
        viewModel.transactions.filter { !$0.isDeleted }
    }

    private var expenses: [Transaction] {
        activeTx.filter { $0.type == .EXPENSE }
    }

    private var totalSpent: Int {
        expenses.sumOf { $0.amountPaise }
    }

    private var upiSpent: Int {
        expenses.filter { $0.paymentMethod == "UPI" }.sumOf { $0.amountPaise }
    }

    private var cashSpent: Int {
        expenses.filter { $0.paymentMethod == "Cash" }.sumOf { $0.amountPaise }
    }

    private var youPaid: Int {
        expenses.filter { $0.paidBy == viewModel.currentUser.id }.sumOf { $0.amountPaise }
    }

    private var partnerPaid: Int {
        totalSpent - youPaid
    }

    private var highestTransaction: Transaction? {
        expenses.maxByOrNull { $0.amountPaise }
    }

    private var categoryBreakdown: [(String, Int)] {
        expenses
            .reduce(into: [String: Int]()) { result, transaction in
                result[transaction.category, default: 0] += transaction.amountPaise
            }
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack { // Using NavigationStack for navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Donut Chart
                    if showContent {
                        DonutChart(data: categoryBreakdown, total: totalSpent)
                            .transition(.opacity.animation(.easeIn(duration: 0.3)).combined(with: .move(edge: .bottom).animation(.easeIn(duration: 0.3))))
                    }

                    // You Paid / Partner Paid Cards
                    if showContent {
                        HStack(spacing: 16) {
                            CardView {
                                Text("You Paid")
                                    .font(.caption) // labelMedium
                                    .foregroundColor(.secondary)
                                Text("₹\(Double(youPaid) / 100.0, specifier: "%.2f")")
                                    .font(.headline) // titleMedium
                                    .fontWeight(.bold)
                            }
                            CardView {
                                Text("Partner Paid")
                                    .font(.caption) // labelMedium
                                    .foregroundColor(.secondary)
                                Text("₹\(Double(partnerPaid) / 100.0, specifier: "%.2f")")
                                    .font(.headline) // titleMedium
                                    .fontWeight(.bold)
                            }
                        }
                        .transition(.opacity.animation(.easeIn(duration: 0.4).delay(0.1)).combined(with: .move(edge: .bottom).animation(.easeIn(duration: 0.4).delay(0.1))))
                    }

                    // UPI / Cash Cards
                    if showContent {
                        HStack(spacing: 16) {
                            CardView(backgroundColor: .secondaryContainer) {
                                Text("UPI")
                                    .font(.caption) // labelMedium
                                    .foregroundColor(.primary)
                                Text("₹\(Double(upiSpent) / 100.0, specifier: "%.2f")")
                                    .font(.headline) // titleMedium
                                    .fontWeight(.bold)
                            }
                            CardView(backgroundColor: .tertiaryContainer) {
                                Text("Cash")
                                    .font(.caption) // labelMedium
                                    .foregroundColor(.primary)
                                Text("₹\(Double(cashSpent) / 100.0, specifier: "%.2f")")
                                    .font(.headline) // titleMedium
                                    .fontWeight(.bold)
                            }
                        }
                        .transition(.opacity.animation(.easeIn(duration: 0.5).delay(0.2)).combined(with: .move(edge: .bottom).animation(.easeIn(duration: 0.5).delay(0.2))))
                    }

                    // Highest Transaction Card
                    if let highestTransaction = highestTransaction, showContent {
                        CardView(backgroundColor: .errorContainer) {
                            Text("Highest Single Transaction")
                                .font(.caption) // labelMedium
                                .foregroundColor(.onErrorContainer)
                            Text("\(highestTransaction.category): ₹\(Double(highestTransaction.amountPaise) / 100.0, specifier: "%.2f")")
                                .font(.headline) // titleMedium
                                .fontWeight(.bold)
                                .foregroundColor(.onErrorContainer)
                            if highestTransaction.notes.isNotBlank {
                                Text(highestTransaction.notes)
                                    .font(.caption2) // bodySmall
                                    .foregroundColor(.onErrorContainer)
                            }
                        }
                        .transition(.opacity.animation(.easeIn(duration: 0.6).delay(0.3)).combined(with: .move(edge: .bottom).animation(.easeIn(duration: 0.6).delay(0.3))))
                    }

                    Spacer().frame(height: 8) // Equivalent to Spacer(modifier = Modifier.height(24.dp))

                    // Category Breakdown Title
                    if showContent {
                        Text("Category Breakdown")
                            .font(.title2) // titleLarge
                            .fontWeight(.bold)
                            .transition(.opacity.animation(.easeIn(duration: 0.7).delay(0.4)))
                    }
                    Spacer().frame(height: 16)

                    // Category Breakdown List
                    if categoryBreakdown.isEmpty {
                        if showContent {
                            Text("No data to display.")
                                .foregroundColor(.onSurfaceVariant)
                                .transition(.opacity.animation(.easeIn(duration: 0.7).delay(0.4)))
                        }
                    } else {
                        ForEach(Array(categoryBreakdown.enumerated()), id: \.offset) { index, item in
                            let (category, amount) = item
                            let percentage = totalSpent > 0 ? Double(amount) / Double(totalSpent) : 0.0

                            if showContent {
                                CategoryBreakdownRow(category: category, amount: amount, percentage: percentage, showContent: showContent, index: index)
                                    .transition(.opacity.animation(.easeIn(duration: 0.8).delay(0.4 + Double(index) * 0.1)).combined(with: .move(edge: .leading).animation(.easeIn(duration: 0.8).delay(0.4 + Double(index) * 0.1))))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8) // Adjust vertical padding for scroll view
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.clear) // Scaffold containerColor = Transparent
            .scrollContentBackground(.hidden) // Make scroll view background transparent
            .onAppear {
                // Trigger the main screen content animation
                withAnimation {
                    showContent = true
                }
            }
        }
    }
}
```