import SwiftUI
import Combine

// MARK: - Models
struct Transaction: Identifiable, Equatable {
    let id: String
    let category: String
    let amountPaise: Int
    let dateMillis: Int64
    let createdBy: String
    let paidBy: String
    let personal: Bool
    let notes: String
    let type: TransactionType
    let isPending: Bool
}

enum TransactionType: String, Codable {
    case INCOME
    case EXPENSE
}

struct User: Identifiable, Equatable {
    let id: String
    let name: String
    // Add other user properties as needed
}

struct LedgerBalance: Equatable {
    let netBalancePaise: Int
    let amountIOwePaise: Int
    let totalSharedPaidByMePaise: Int
    let totalSharedPaidByPartnerPaise: Int
}

// MARK: - ViewModel
class DashboardViewModel: ObservableObject {
    @Published var state: DashboardState
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initial dummy state for demonstration
        self.state = DashboardState(
            isLoading: true,
            currentUser: User(id: "user1", name: "You"),
            partnerUser: User(id: "user2", name: "Friend"),
            balance: LedgerBalance(netBalancePaise: 0, amountIOwePaise: 0, totalSharedPaidByMePaise: 0, totalSharedPaidByPartnerPaise: 0),
            transactions: []
        )

        // Simulate data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.state.isLoading = false
            self.state.balance = LedgerBalance(netBalancePaise: -5000, amountIOwePaise: 5000, totalSharedPaidByMePaise: 10000, totalSharedPaidByPartnerPaise: 15000)
            self.state.transactions = [
                Transaction(id: UUID().uuidString, category: "Food & Dining", amountPaise: 12500, dateMillis: Date().addingTimeInterval(-3600 * 24 * 2).timeIntervalSince1970 * 1000, createdBy: "user1", paidBy: "user1", personal: false, notes: "Dinner with friend", type: .EXPENSE, isPending: false),
                Transaction(id: UUID().uuidString, category: "Groceries", amountPaise: 7500, dateMillis: Date().addingTimeInterval(-3600 * 24 * 1).timeIntervalSince1970 * 1000, createdBy: "user2", paidBy: "user2", personal: false, notes: "Weekly groceries", type: .EXPENSE, isPending: false),
                Transaction(id: UUID().uuidString, category: "Transport", amountPaise: 2000, dateMillis: Date().addingTimeInterval(-3600 * 12).timeIntervalSince1970 * 1000, createdBy: "user1", paidBy: "user1", personal: true, notes: "Taxi to work", type: .EXPENSE, isPending: false),
                Transaction(id: UUID().uuidString, category: "Shopping", amountPaise: 3000, dateMillis: Date().addingTimeInterval(-3600 * 6).timeIntervalSince1970 * 1000, createdBy: "user1", paidBy: "user2", personal: false, notes: "New shirt", type: .EXPENSE, isPending: true),
                Transaction(id: UUID().uuidString, category: "Income", amountPaise: 50000, dateMillis: Date().addingTimeInterval(-3600 * 24 * 5).timeIntervalSince1970 * 1000, createdBy: "user1", paidBy: "user1", personal: true, notes: "Salary", type: .INCOME, isPending: false)
            ]
        }
    }

    func deleteTransaction(_ id: String) {
        state.transactions.removeAll { $0.id == id }
        // In a real app, this would also call a service to delete from backend
    }
}

struct DashboardState {
    var isLoading: Bool
    var currentUser: User
    var partnerUser: User?
    var balance: LedgerBalance
    var transactions: [Transaction]
}

// MARK: - Custom Colors
extension Color {
    static let primaryGreen = Color(red: 0/255, green: 107/255, blue: 91/255) // 0xFF006B5B
    static let darkGreen = Color(red: 0/255, green: 80/255, blue: 73/255) // 0xFF005049
    static let darkBlueGray = Color(red: 50/255, green: 64/255, blue: 72/255) // 0xFF324048
    static let darkSurface = Color(red: 26/255, green: 28/255, blue: 30/255) // 0xFF1A1C1E
    static let customOutline = Color.white.opacity(0.3) // For search field border
}

// MARK: - DashboardScreen
struct DashboardScreen: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onAddExpense: () -> Void
    var onEditExpense: (String) -> Void
    var onSettleUp: () -> Void
    var onSettings: () -> Void

    @State private var searchQuery: String = ""
    @State private var isFabVisible: Bool = false
    @State private var path = NavigationPath() // For NavigationStack

    var body: some View {
        NavigationStack(path: $path) {
            ZStack { // Use ZStack for background color
                Color.darkSurface.ignoresSafeArea() // Scaffold containerColor = Transparent, so set background here

                VStack(spacing: 0) {
                    if viewModel.state.isLoading {
                        ProgressView()
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        let filteredTxs = viewModel.state.transactions.filter { tx in
                            searchQuery.isEmpty ||
                            tx.category.localizedCaseInsensitiveContains(searchQuery) ||
                            tx.notes.localizedCaseInsensitiveContains(searchQuery)
                        }

                        ScrollView {
                            VStack(spacing: 16) {
                                BalanceCard(balance: viewModel.state.balance, partnerName: viewModel.state.partnerUser?.name ?? "Friend")
                                    .padding(.horizontal, 16)

                                Text("Recent Transactions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)

                                TextField("Search transactions...", text: $searchQuery)
                                    .padding(.vertical, 12)
                                    .padding(.leading, 40) // For leading icon
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.customOutline, lineWidth: 1)
                                            .background(Color.white.opacity(0.05).cornerRadius(16))
                                    )
                                    .overlay(
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 12)
                                            Spacer()
                                        }
                                    )
                                    .foregroundColor(.white)
                                    .accentColor(.primaryGreen) // Cursor color
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)

                                if filteredTxs.isEmpty {
                                    VStack(alignment: .center, spacing: 16) {
                                        Canvas { context, size in
                                            let center = CGPoint(x: size.width / 2, y: size.height / 2)
                                            context.fill(Path(ellipseIn: CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)), with: .color(Color.primaryGreen.opacity(0.1)))
                                            context.fill(Path(ellipseIn: CGRect(x: center.x - size.width / 3, y: center.y - size.height / 3, width: size.width * 2 / 3, height: size.height * 2 / 3)), with: .color(Color.primaryGreen.opacity(0.2)))

                                            // Stylized document/receipt icon
                                            let rectWidth = size.width * 0.3
                                            let rectHeight = size.height * 0.5
                                            let rectX = size.width * 0.35
                                            let rectY = size.height * 0.25
                                            let cornerRadius: CGFloat = 8

                                            var documentPath = Path()
                                            documentPath.addRoundedRect(in: CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                                            context.stroke(documentPath, with: .color(Color.primaryGreen), lineWidth: 3) // Stroke width 6f in Compose is 3 in SwiftUI for similar visual weight

                                            context.stroke(Path { p in
                                                p.move(to: CGPoint(x: size.width * 0.45, y: size.height * 0.4))
                                                p.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.4))
                                            }, with: .color(Color.primaryGreen), lineWidth: 3, lineCap: .round)

                                            context.stroke(Path { p in
                                                p.move(to: CGPoint(x: size.width * 0.45, y: size.height * 0.55))
                                                p.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.55))
                                            }, with: .color(Color.primaryGreen), lineWidth: 3, lineCap: .round)
                                        }
                                        .frame(width: 120, height: 120)

                                        Text("No transactions yet.")
                                            .font(.title3)
                                            .foregroundColor(.primaryGreen)
                                            .fontWeight(.bold)
                                        Text("Tap the + button to add your first expense")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                }

                                ForEach(filteredTxs) { tx in
                                    TransactionItem(
                                        tx: tx,
                                        currentUserId: viewModel.state.currentUser.id,
                                        partnerUser: viewModel.state.partnerUser,
                                        onEdit: { onEditExpense(tx.id) },
                                        onDelete: {
                                            viewModel.deleteTransaction(tx.id)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .transition(.opacity.animation(.easeOut(duration: 0.3))) // Equivalent to animateItem()
                                }
                            }
                            .padding(.bottom, 80) // To account for FAB
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(alignment: .leading) {
                            Text("OurMoney")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Connected with \(viewModel.state.partnerUser?.name ?? "Friend")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: onSettings) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.darkSurface, for: .navigationBar) // Match ZStack background
                .navigationBarTitleDisplayMode(.inline)

                // Floating Action Buttons
                VStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        if isFabVisible {
                            Button(action: onSettleUp) {
                                Text("Settle")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .frame(height: 40)
                                    .background(Color.darkBlueGray.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                        if isFabVisible {
                            Button(action: onAddExpense) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .frame(width: 56, height: 56)
                                    .background(Color.primaryGreen)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5).delay(0.1)) {
                    isFabVisible = true
                }
            }
            .navigationDestination(for: String.self) { destination in
                // Placeholder for navigation destinations
                // In a real app, you'd map `destination` to actual views
                Text("Navigated to \(destination)")
            }
        }
    }
}

// MARK: - BalanceCard
struct BalanceCard: View {
    let balance: LedgerBalance
    let partnerName: String

    @State private var waveOffset: Double = 0.0

    var body: some View {
        ElevatedCardContainer {
            ZStack {
                // Animated Abstract Graphic Background
                TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
                    Canvas { context, size in
                        let color1 = Color.darkGreen
                        let color2 = Color.darkBlueGray
                        let color3 = Color.darkSurface

                        let gradient = Gradient(colors: [color1, color2, color3, color1])
                        let startPoint = CGPoint(x: waveOffset * 80, y: 0)
                        let endPoint = CGPoint(x: size.width + (waveOffset * 80), y: size.height)

                        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint))
                    }
                    .onAppear {
                        // Start animation
                        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                            waveOffset = 2 * .pi // Target value for the animation
                        }
                    }
                }
                .opacity(0.4) // Match alpha from Compose

                // Foreground Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settlement Balance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    let balanceText: String
                    if balance.netBalancePaise > 0 {
                        balanceText = "\(partnerName) owes you\n₹\(String(format: "%.2f", Double(balance.netBalancePaise) / 100.0))"
                    } else if balance.netBalancePaise < 0 {
                        balanceText = "You owe \(partnerName)\n₹\(String(format: "%.2f", Double(abs(balance.netBalancePaise)) / 100.0))"
                    } else {
                        balanceText = "All settled ✓"
                    }
                    Text(balanceText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true) // Allow multiline text

                    Spacer().frame(height: 16)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("You Paid")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("₹\(String(format: "%.2f", Double(balance.totalSharedPaidByMePaise) / 100.0))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("\(partnerName) Paid")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("₹\(String(format: "%.2f", Double(balance.totalSharedPaidByPartnerPaise) / 100.0))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Total Shared")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("₹\(String(format: "%.2f", Double(balance.totalSharedPaidByMePaise + balance.totalSharedPaidByPartnerPaise) / 100.0))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white.opacity(0.1)) // containerColor
        .cornerRadius(32)
    }
}

// MARK: - TransactionItem
struct TransactionItem: View {
    let tx: Transaction
    let currentUserId: String
    let partnerUser: User?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm: Bool = false
    @State private var waveOffset: Double = 0.0 // For the animated background

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, hh:mm a"
        formatter.locale = Locale.current
        return formatter
    }

    var body: some View {
        Button(action: {
            onEdit?() // Main action on tap
        }) {
            ElevatedCardContainer {
                ZStack {
                    // Animated Abstract Graphic Background
                    TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
                        Canvas { context, size in
                            let color1 = Color.darkGreen
                            let color2 = Color.darkBlueGray
                            let color3 = Color.darkSurface

                            let gradient = Gradient(colors: [color1, color2, color3, color1])
                            let startPoint = CGPoint(x: waveOffset * 80, y: 0)
                            let endPoint = CGPoint(x: size.width + (waveOffset * 80), y: size.height)

                            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint))
                        }
                        .onAppear {
                            // Start animation
                            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                                waveOffset = 2 * .pi // Target value for the animation
                            }
                        }
                    }
                    .opacity(0.4) // Match alpha from Compose

                    HStack(alignment: .center, spacing: 16) {
                        Image(systemName: getCategorySFSymbol(tx.category))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.darkBlueGray.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(tx.category)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            if tx.personal {
                                let isMine = tx.createdBy == currentUserId || tx.paidBy == currentUserId
                                let personalOwner = isMine ? "My Personal" : "\(partnerUser?.name ?? "Friend")'s Personal"
                                Text(personalOwner)
                                    .font(.footnote)
                                    .foregroundColor(.orange) // MaterialTheme.colorScheme.secondary
                                    .fontWeight(.medium)
                            } else {
                                let payer = tx.paidBy == currentUserId ? "You" : (partnerUser?.name ?? "Friend")
                                Text("Shared • Paid by \(payer)")
                                    .font(.footnote)
                                    .foregroundColor(.gray) // MaterialTheme.colorScheme.onSurfaceVariant
                            }
                            Text(dateFormatter.string(from: Date(timeIntervalSince1970: Double(tx.dateMillis) / 1000)))
                                .font(.caption2)
                                .foregroundColor(.secondary) // MaterialTheme.colorScheme.outline
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center) {
                            if tx.isPending {
                                Text("Syncing...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Text("₹\(String(format: "%.2f", Double(tx.amountPaise) / 100.0))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(tx.type == .INCOME ? .green : .white) // MaterialTheme.colorScheme.primary vs onSurface

                            if onEdit != nil || onDelete != nil {
                                Menu {
                                    if let onEdit = onEdit {
                                        Button("Edit") { onEdit() }
                                    }
                                    if let onDelete = onDelete {
                                        Button("Delete") { showDeleteConfirm = true }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.white)
                                        .padding(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.darkBlueGray.opacity(0.6)) // containerColor
            .cornerRadius(20)
        }
        .buttonStyle(CardPressEffectButtonStyle()) // Apply custom button style for press animation
        .confirmationDialog("Delete Transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This may affect your balance, budgets and analytics.")
        }
    }
}

// MARK: - Helper for ElevatedCard styling
struct ElevatedCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

// MARK: - Custom ButtonStyle for press animation
struct CardPressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: configuration.isPressed ? 1 : 4, x: 0, y: configuration.isPressed ? 0.5 : 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Category Icon Mapping
func getCategorySFSymbol(_ category: String) -> String {
    switch category.lowercased() {
    case "food & dining", "food", "dining", "restaurant": return "fork.knife"
    case "groceries", "supermarket": return "cart.fill"
    case "transport", "taxi", "bus", "flight": return "car.fill"
    case "shopping", "clothes": return "bag.fill"
    case "entertainment", "movies", "games": return "popcorn.fill"
    case "bills & utilities", "utilities", "electricity", "water": return "doc.text.fill"
    case "health", "medical", "pharmacy": return "cross.case.fill"
    case "travel", "hotel", "vacation": return "airplane"
    case "education", "books", "school": return "book.closed.fill"
    case "income": return "dollarsign.circle.fill" // Specific for income
    default: return "dollarsign.circle" // Default for other expenses
    }
}