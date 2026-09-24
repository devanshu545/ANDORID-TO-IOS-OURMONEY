import Foundation
import Combine

// MARK: - Models
// These models are converted from their Kotlin counterparts.
// In a full project, these would typically reside in separate files.

struct User: Identifiable, Equatable {
    let id: String
    var name: String
}

struct Household: Identifiable {
    let id: String
    let members: [String] // User IDs
}

struct LedgerBalance: Equatable {
    var amount: Int = 0 // Example, adjust based on actual LedgerBalance properties
}

struct Settlement: Identifiable, Equatable {
    let id: String
    var amountPaise: Int
    var paidBy: String // User ID
    var receivedBy: String // User ID
    var dateMillis: Int64
    var paymentMethod: String
    var notes: String
    var createdBy: String // User ID
}

struct Transaction: Identifiable, Equatable {
    let id: String
    // Add other transaction properties as needed
}

// MARK: - Repositories and Calculator
// These are converted from their Kotlin counterparts.
// They simulate asynchronous operations and Flow behavior using Swift Concurrency and Combine.

class LedgerRepository {
    let householdId: String
    let currentUserId: String

    // Using CurrentValueSubject to simulate Kotlin's MutableStateFlow for data streams
    private let _transactions = CurrentValueSubject<[Transaction], Never>([])
    private let _settlements = CurrentValueSubject<[Settlement], Never>([])

    init(householdId: String, currentUserId: String) {
        self.householdId = householdId
        self.currentUserId = currentUserId
        // Simulate some initial data for settlements
        _settlements.value = [
            Settlement(id: "s1", amountPaise: 10000, paidBy: "user1", receivedBy: "user2", dateMillis: Date().timeIntervalSince1970.milliseconds, paymentMethod: "UPI", notes: "Initial settlement", createdBy: "user1")
        ]
    }

    func getTransactions() -> AnyPublisher<[Transaction], Never> {
        _transactions.eraseToAnyPublisher()
    }

    func getSettlements() -> AnyPublisher<[Settlement], Never> {
        _settlements.eraseToAnyPublisher()
    }

    func getSettlementSuspend(_ settlementId: String) async throws -> Settlement? {
        // Simulate an asynchronous network call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        return _settlements.value.first(where: { $0.id == settlementId })
    }

    func deleteSettlement(_ settlementId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        _settlements.value.removeAll(where: { $0.id == settlementId })
    }

    func updateSettlement(_ settlement: Settlement) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        if let index = _settlements.value.firstIndex(where: { $0.id == settlement.id }) {
            _settlements.value[index] = settlement
        } else {
            throw SettleUpError.genericError("Settlement not found for update.")
        }
    }

    func addSettlement(_ settlement: Settlement) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        _settlements.value.append(settlement)
    }
}

class UserRepository {
    func getUserSuspend(_ userId: String) async throws -> User? {
        // Simulate an asynchronous network call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        if userId == "partner123" { // Example partner ID
            return User(id: "partner123", name: "Alex")
        }
        return nil
    }
}

class LedgerCalculator {
    func calculateNetBalance(_ currentUserId: String, _ transactions: [Transaction], _ settlements: [Settlement]) -> LedgerBalance {
        // Simplified calculation for conversion purpose
        let totalSettledByMe = settlements.filter { $0.paidBy == currentUserId }.map { $0.amountPaise }.reduce(0, +)
        let totalSettledToMe = settlements.filter { $0.receivedBy == currentUserId }.map { $0.amountPaise }.reduce(0, +)
        return LedgerBalance(amount: totalSettledByMe - totalSettledToMe)
    }
}

// MARK: - Helper Extensions

extension TimeInterval {
    var milliseconds: Int64 {
        Int64(self * 1000)
    }
}

extension Int64 {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self) / 1000)
    }
}

// Extension to allow `copy` method for Settlement, similar to Kotlin's data class
extension Settlement {
    func copy(
        id: String? = nil,
        amountPaise: Int? = nil,
        paidBy: String? = nil,
        receivedBy: String? = nil,
        dateMillis: Int64? = nil,
        paymentMethod: String? = nil,
        notes: String? = nil,
        createdBy: String? = nil
    ) -> Settlement {
        Settlement(
            id: id ?? self.id,
            amountPaise: amountPaise ?? self.amountPaise,
            paidBy: paidBy ?? self.paidBy,
            receivedBy: receivedBy ?? self.receivedBy,
            dateMillis: dateMillis ?? self.dateMillis,
            paymentMethod: paymentMethod ?? self.paymentMethod,
            notes: notes ?? self.notes,
            createdBy: createdBy ?? self.createdBy
        )
    }
}

// Custom Error for SettleUpViewModel
enum SettleUpError: LocalizedError {
    case invalidAmount
    case noPartner
    case settlementNotFound
    case genericError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than 0."
        case .noPartner:
            return "No partner to settle with."
        case .settlementNotFound:
            return "Settlement not found."
        case .genericError(let message):
            return message
        }
    }
}

// MARK: - SettleUpViewModel

class SettleUpViewModel: ObservableObject {

    let currentUser: User
    let household: Household
    private let ledgerRepository: LedgerRepository
    private let ledgerCalculator: LedgerCalculator
    private let userRepository: UserRepository

    private let partnerId: String

    @Published var partnerName: String = "Friend"

    private var editingSettlementId: String?
    private var loadedSettlement: Settlement?

    @Published var initialDataLoaded: Bool = false

    @Published var initialAmountStr: String = ""
    @Published var initialPaidByMe: Bool = true
    @Published var initialPaymentMethod: String = "UPI"
    @Published var initialNotes: String = ""
    @Published var initialDateMillis: Int64 = Date().timeIntervalSince1970.milliseconds

    @Published var balance: LedgerBalance = LedgerBalance()
    @Published var settlements: [Settlement] = []

    @Published var isSaving: Bool = false
    @Published var error: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init(currentUser: User, household: Household, ledgerRepository: LedgerRepository? = nil, ledgerCalculator: LedgerCalculator? = nil, userRepository: UserRepository? = nil) {
        self.currentUser = currentUser
        self.household = household
        self.ledgerRepository = ledgerRepository ?? LedgerRepository(householdId: household.id, currentUserId: currentUser.id)
        self.ledgerCalculator = ledgerCalculator ?? LedgerCalculator()
        self.userRepository = userRepository ?? UserRepository()

        self.partnerId = household.members.first(where: { $0 != currentUser.id }) ?? ""

        setupCombinePublishers()

        if !partnerId.isEmpty {
            Task {
                do {
                    if let partner = try await self.userRepository.getUserSuspend(self.partnerId), !partner.name.isEmpty {
                        await MainActor.run {
                            self.partnerName = partner.name
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to load partner name: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func setupCombinePublishers() {
        Publishers.CombineLatest(
            ledgerRepository.getTransactions(),
            ledgerRepository.getSettlements()
        )
        .map { [weak self] transactions, settlements in
            guard let self = self else { return LedgerBalance() }
            return self.ledgerCalculator.calculateNetBalance(self.currentUser.id, transactions, settlements)
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.balance, on: self)
        .store(in: &cancellables)

        ledgerRepository.getSettlements()
            .map { settlements in
                settlements.sorted { $0.dateMillis > $1.dateMillis }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.settlements, on: self)
            .store(in: &cancellables)
    }

    func loadSettlement(settlementId: String) {
        if editingSettlementId == settlementId { return }
        editingSettlementId = settlementId
        Task {
            do {
                let s = try await ledgerRepository.getSettlementSuspend(settlementId)
                await MainActor.run {
                    self.loadedSettlement = s
                    if let settlement = s {
                        // Convert amountPaise to String, removing ".0" if it's an integer value
                        let amountDouble = Double(settlement.amountPaise) / 100.0
                        if amountDouble.truncatingRemainder(dividingBy: 1) == 0 {
                            self.initialAmountStr = String(format: "%.0f", amountDouble)
                        } else {
                            self.initialAmountStr = String(amountDouble)
                        }
                        self.initialPaidByMe = settlement.paidBy == self.currentUser.id
                        self.initialPaymentMethod = settlement.paymentMethod
                        self.initialNotes = settlement.notes
                    }
                    self.initialDataLoaded = true
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.initialDataLoaded = true // Still set to true to indicate loading finished, even if with error
                }
            }
        }
    }

    func setModeCreate() {
        editingSettlementId = nil
        loadedSettlement = nil
        initialDataLoaded = true // Indicate that the "create" mode is ready
        // Reset initial values for create mode
        initialAmountStr = ""
        initialPaidByMe = true
        initialPaymentMethod = "UPI"
        initialNotes = ""
        initialDateMillis = Date().timeIntervalSince1970.milliseconds
    }

    func deleteSettlement(settlementId: String, onSuccess: @escaping () -> Void) {
        Task {
            await MainActor.run {
                self.error = nil
            }
            do {
                try await ledgerRepository.deleteSettlement(settlementId)
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func saveSettlement(
        amountPaise: Int,
        paidByCurrentUser: Bool,
        paymentMethod: String,
        notes: String,
        dateMillis: Int64, // This parameter is currently unused for new settlements, matching Kotlin's behavior
        onSuccess: @escaping () -> Void
    ) {
        Task {
            await MainActor.run {
                self.isSaving = true
                self.error = nil
            }
            do {
                if amountPaise <= 0 { throw SettleUpError.invalidAmount }
                if partnerId.isEmpty { throw SettleUpError.noPartner }

                let paidBy = paidByCurrentUser ? currentUser.id : partnerId
                let receivedBy = paidByCurrentUser ? partnerId : currentUser.id

                let sId = editingSettlementId ?? UUID().uuidString

                let settlement: Settlement
                if let existingSettlementId = editingSettlementId {
                    guard let existing = loadedSettlement else { throw SettleUpError.settlementNotFound }
                    settlement = existing.copy(
                        amountPaise: amountPaise,
                        paidBy: paidBy,
                        receivedBy: receivedBy,
                        paymentMethod: paymentMethod,
                        notes: notes
                    )
                } else {
                    settlement = Settlement(
                        id: sId,
                        amountPaise: amountPaise,
                        paidBy: paidBy,
                        receivedBy: receivedBy,
                        dateMillis: Date().timeIntervalSince1970.milliseconds, // Use current time for new settlements
                        paymentMethod: paymentMethod,
                        notes: notes,
                        createdBy: currentUser.id
                    )
                }

                if editingSettlementId != nil {
                    try await ledgerRepository.updateSettlement(settlement)
                } else {
                    try await ledgerRepository.addSettlement(settlement)
                }

                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
            await MainActor.run { // This ensures it runs after do-catch, similar to Kotlin's finally
                self.isSaving = false
            }
        }
    }
}