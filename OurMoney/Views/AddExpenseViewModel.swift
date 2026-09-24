final class AddExpenseViewModel: ObservableObject {
    let currentUser: User
    let household: Household
    private let ledgerRepository: LedgerRepository
    private let userRepository: UserRepository

    let otherUserId: String
    @Published var partnerName: String = "Friend"

    private var editingTransactionId: String?
    private var loadedTransaction: Transaction?

    @Published var initialDataLoaded: Bool = false

    @Published var initialAmountStr: String = ""
    @Published var initialCategory: String = ""
    @Published var initialPaymentMethod: String = "UPI"
    @Published var initialNotes: String = ""
    @Published var initialIsPersonal: Bool = false
    @Published var initialPaidByMe: Bool = true
    @Published var initialDateMillis: Int64 = Date().millisecondsSince1970

    @Published var customCategories: [CustomCategory] = []
    private var cancellables = Set<AnyCancellable>()

    @Published var isSaving: Bool = false
    @Published var error: String? = nil

    init(currentUser: User, household: Household) {
        self.currentUser = currentUser
        self.household = household
        self.ledgerRepository = LedgerRepository(householdId: household.id, currentUserId: currentUser.id)
        self.userRepository = UserRepository()
        self.otherUserId = household.members.first(where: { $0 != currentUser.id }) ?? ""

        if !otherUserId.isEmpty {
            Task {
                do {
                    let partner = try await userRepository.getUserSuspend(otherUserId)
                    if let partner = partner, !partner.name.isBlank {
                        await MainActor.run {
                            self.partnerName = partner.name
                        }
                    }
                } catch {
                    print("Error loading partner name: \(error.localizedDescription)")
                    // Optionally handle error, e.g., self.error = "Failed to load partner name."
                }
            }
        }

        // Subscribe to custom categories flow
        ledgerRepository.getCustomCategories()
            .replaceError(with: []) // Handle errors by providing an empty list
            .receive(on: DispatchQueue.main) // Ensure updates are on the main thread
            .sink { [weak self] categories in
                self?.customCategories = categories
            }
            .store(in: &cancellables)
    }

    func addCustomCategory(name: String) async {
        guard !name.isBlank else { return }
        let category = CustomCategory(name: name.trimmingCharacters(in: .whitespacesAndNewlines), createdBy: currentUser.id)
        await ledgerRepository.addCustomCategory(category)
    }

    func deleteCustomCategory(categoryId: String) async {
        await ledgerRepository.deleteCustomCategory(categoryId)
    }

    func loadTransaction(transactionId: String) async {
        guard editingTransactionId != transactionId else { return }
        editingTransactionId = transactionId
        do {
            let tx = try await ledgerRepository.getTransactionSuspend(transactionId)
            await MainActor.run {
                self.loadedTransaction = tx
                if let tx = tx {
                    self.initialAmountStr = (Double(tx.amountPaise) / 100.0).formattedAmountString()
                    self.initialCategory = tx.category
                    self.initialPaymentMethod = tx.paymentMethod
                    self.initialNotes = tx.notes
                    self.initialIsPersonal = tx.personal
                    self.initialPaidByMe = tx.paidBy == currentUser.id
                    self.initialDateMillis = tx.dateMillis
                }
                self.initialDataLoaded = true
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load transaction: \(error.localizedDescription)"
                self.initialDataLoaded = true // Still set to true to indicate loading finished
            }
        }
    }

    func setModeCreate() {
        editingTransactionId = nil
        loadedTransaction = nil
        initialDataLoaded = true
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
    ) async {
        await MainActor.run {
            self.isSaving = true
            self.error = nil
        }

        do {
            guard amountPaise > 0 else { throw ExpenseError.invalidAmount }
            guard !category.isBlank else { throw ExpenseError.categoryRequired }

            let txId = editingTransactionId ?? UUID().uuidString

            let targetUser = paidByCurrentUser ? currentUser.id : otherUserId
            let payerId = paidByCurrentUser ? currentUser.id : otherUserId
            let creatorId = isPersonal ? targetUser : currentUser.id

            let tx: Transaction
            if let editingTransactionId = editingTransactionId {
                guard let existing = loadedTransaction else { throw ExpenseError.transactionNotFound }
                tx = existing.copy(
                    amountPaise: amountPaise,
                    category: category,
                    paidBy: payerId,
                    personal: isPersonal,
                    splitMethod: splitMethod,
                    splits: splits,
                    notes: notes,
                    paymentMethod: paymentMethod,
                    dateMillis: dateMillis,
                    createdBy: isPersonal ? targetUser : existing.createdBy
                )
            } else {
                tx = Transaction(
                    id: txId,
                    amountPaise: amountPaise,
                    category: category,
                    paidBy: payerId,
                    personal: isPersonal,
                    splitMethod: splitMethod,
                    splits: splits,
                    notes: notes,
                    paymentMethod: paymentMethod,
                    createdBy: creatorId,
                    dateMillis: dateMillis
                )
            }

            if editingTransactionId != nil {
                try await ledgerRepository.updateTransaction(tx)
            } else {
                try await ledgerRepository.addTransaction(tx)
            }

            await MainActor.run {
                onSuccess()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        await MainActor.run {
            self.isSaving = false
        }
    }
}

// MARK: - Helper Extensions and Error Enum

import Foundation
import Combine

enum ExpenseError: LocalizedError {
    case invalidAmount
    case categoryRequired
    case transactionNotFound

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "Amount must be greater than 0."
        case .categoryRequired: return "Category is required."
        case .transactionNotFound: return "Transaction not found for editing."
        }
    }
}

extension String {
    var isBlank: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Double {
    func formattedAmountString() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(millisecondsSince1970: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(millisecondsSince1970) / 1000.0)
    }
}

// MARK: - Mock Model and Repository Implementations (for compilation and demonstration)
// In a real project, these would be in separate files and properly implemented.

struct User: Identifiable, Equatable, Codable {
    let id: String
    var name: String
}

struct Household: Identifiable, Equatable, Codable {
    let id: String
    var members: [String]
}

struct SplitAmount: Equatable, Codable {
    let userId: String
    let amountPaise: Int64
}

enum SplitMethod: String, Codable, CaseIterable, Identifiable {
    case equal = "Equal"
    case percentage = "Percentage"
    case exact = "Exact"

    var id: String { self.rawValue }
}

struct Transaction: Identifiable, Equatable, Codable {
    let id: String
    var amountPaise: Int64
    var category: String
    var paidBy: String // User ID who paid
    var personal: Bool // If true, it's a personal expense for 'paidBy' user
    var splitMethod: SplitMethod
    var splits: [SplitAmount] // How the amount is split among members
    var notes: String
    var paymentMethod: String
    var createdBy: String // User ID who created the transaction
    var dateMillis: Int64 // Date in milliseconds since epoch

    // Kotlin's data class copy method equivalent
    func copy(
        id: String? = nil,
        amountPaise: Int64? = nil,
        category: String? = nil,
        paidBy: String? = nil,
        personal: Bool? = nil,
        splitMethod: SplitMethod? = nil,
        splits: [SplitAmount]? = nil,
        notes: String? = nil,
        paymentMethod: String? = nil,
        createdBy: String? = nil,
        dateMillis: Int64? = nil
    ) -> Transaction {
        Transaction(
            id: id ?? self.id,
            amountPaise: amountPaise ?? self.amountPaise,
            category: category ?? self.category,
            paidBy: paidBy ?? self.paidBy,
            personal: personal ?? self.personal,
            splitMethod: splitMethod ?? self.splitMethod,
            splits: splits ?? self.splits,
            notes: notes ?? self.notes,
            paymentMethod: paymentMethod ?? self.paymentMethod,
            createdBy: createdBy ?? self.createdBy,
            dateMillis: dateMillis ?? self.dateMillis
        )
    }
}

struct CustomCategory: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    let createdBy: String
    let createdAtMillis: Int64

    init(id: String = UUID().uuidString, name: String, createdBy: String, createdAtMillis: Int64 = Date().millisecondsSince1970) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAtMillis = createdAtMillis
    }
}

// Mock LedgerRepository
class LedgerRepository {
    private let householdId: String
    private let currentUserId: String
    private var _customCategories = CurrentValueSubject<[CustomCategory], Error>([])
    private var _transactions = CurrentValueSubject<[Transaction], Error>([])

    init(householdId: String, currentUserId: String) {
        self.householdId = householdId
        self.currentUserId = currentUserId
        // Simulate loading initial data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self._customCategories.send([
                CustomCategory(name: "Groceries", createdBy: currentUserId),
                CustomCategory(name: "Rent", createdBy: currentUserId)
            ])
            self._transactions.send([
                Transaction(id: "tx1", amountPaise: 10000, category: "Groceries", paidBy: currentUserId, personal: false, splitMethod: .equal, splits: [], notes: "Weekly shop", paymentMethod: "UPI", createdBy: currentUserId, dateMillis: Date().millisecondsSince1970)
            ])
        }
    }

    func getCustomCategories() -> AnyPublisher<[CustomCategory], Error> {
        _customCategories.eraseToAnyPublisher()
    }

    func addCustomCategory(_ category: CustomCategory) async {
        await MainActor.run {
            var current = _customCategories.value
            if !current.contains(where: { $0.id == category.id }) {
                current.append(category)
                _customCategories.send(current)
            }
        }
    }

    func deleteCustomCategory(_ categoryId: String) async {
        await MainActor.run {
            var current = _customCategories.value
            current.removeAll(where: { $0.id == categoryId })
            _customCategories.send(current)
        }
    }

    func getTransactionSuspend(_ transactionId: String) async throws -> Transaction? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return _transactions.value.first(where: { $0.id == transactionId })
    }

    func updateTransaction(_ transaction: Transaction) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            var current = _transactions.value
            if let index = current.firstIndex(where: { $0.id == transaction.id }) {
                current[index] = transaction
                _transactions.send(current)
            } else {
                _transactions.send(completion: .failure(ExpenseError.transactionNotFound))
            }
        }
    }

    func addTransaction(_ transaction: Transaction) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            var current = _transactions.value
            current.append(transaction)
            _transactions.send(current)
        }
    }
}

// Mock UserRepository
class UserRepository {
    private var users: [String: User] = [
        "user1": User(id: "user1", name: "Alice"),
        "user2": User(id: "user2", name: "Bob")
    ]

    func getUserSuspend(_ userId: String) async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        return users[userId]
    }
}