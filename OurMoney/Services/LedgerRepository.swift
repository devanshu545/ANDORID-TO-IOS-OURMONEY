import FirebaseFirestore
import FirebaseFirestoreSwift // For @DocumentID and data(as:)
import Combine
import Foundation // For Date, UUID, etc.

class LedgerRepository {
    private let db = Firestore.firestore()
    private let householdRef: DocumentReference

    let householdId: String
    let currentUserId: String

    init(householdId: String, currentUserId: String) {
        self.householdId = householdId
        self.currentUserId = currentUserId
        self.householdRef = db.collection("households").document(householdId)
    }

    func getTransactions() -> AnyPublisher<[Transaction], Error> {
        let sharedTransactionsSubject = PassthroughSubject<[Transaction], Error>()
        let personalTransactionsSubject = PassthroughSubject<[Transaction], Error>()

        let sharedListener = householdRef.collection("transactions")
            .whereField("personal", isEqualTo: false)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for shared transactions. \(error.localizedDescription)")
                    sharedTransactionsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let transactions = snapshot.documents.compactMap { doc -> Transaction? in
                    do {
                        var tx = try doc.data(as: Transaction.self)
                        if tx.isDeleted == true { return nil }
                        tx.isPending = doc.metadata.hasPendingWrites
                        return tx
                    } catch {
                        print("Error decoding shared transaction: \(error.localizedDescription)")
                        return nil
                    }
                }
                sharedTransactionsSubject.send(transactions)
            }

        let personalListener = householdRef.collection("transactions")
            .whereField("personal", isEqualTo: true)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for personal transactions. \(error.localizedDescription)")
                    personalTransactionsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let transactions = snapshot.documents.compactMap { doc -> Transaction? in
                    do {
                        var tx = try doc.data(as: Transaction.self)
                        if tx.isDeleted == true { return nil }
                        tx.isPending = doc.metadata.hasPendingWrites
                        return tx
                    } catch {
                        print("Error decoding personal transaction: \(error.localizedDescription)")
                        return nil
                    }
                }
                personalTransactionsSubject.send(transactions)
            }

        return Publishers.CombineLatest(sharedTransactionsSubject, personalTransactionsSubject)
            .map { shared, personal in
                (shared + personal).sorted { $0.dateMillis > $1.dateMillis }
            }
            .handleEvents(receiveCancel: {
                sharedListener.remove()
                personalListener.remove()
            })
            .eraseToAnyPublisher()
    }

    func getTransaction(transactionId: String) async throws -> Transaction? {
        do {
            let doc = try await householdRef.collection("transactions").document(transactionId).getDocument()
            return try doc.data(as: Transaction.self)
        } catch {
            print("Error fetching transaction \(transactionId): \(error.localizedDescription)")
            throw error
        }
    }

    func addTransaction(_ transaction: Transaction) {
        var newTransaction = transaction
        if newTransaction.createdBy.isEmpty {
            newTransaction.createdBy = currentUserId
        }
        do {
            try householdRef.collection("transactions").document(newTransaction.id ?? UUID().uuidString).setData(from: newTransaction)
        } catch {
            print("Error adding transaction: \(error.localizedDescription)")
        }
    }

    func updateTransaction(_ transaction: Transaction) {
        guard let id = transaction.id else {
            print("Error updating transaction: Transaction ID is nil.")
            return
        }
        do {
            try householdRef.collection("transactions").document(id).setData(from: transaction)
        } catch {
            print("Error updating transaction: \(error.localizedDescription)")
        }
    }

    func resetAllTransactions() async throws {
        let batch = db.batch()

        let sharedDocsSnapshot = try await householdRef.collection("transactions").whereField("personal", isEqualTo: false).getDocuments()
        for doc in sharedDocsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        let personalDocsSnapshot = try await householdRef.collection("transactions").whereField("personal", isEqualTo: true).whereField("createdBy", isEqualTo: currentUserId).getDocuments()
        for doc in personalDocsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        let settlementsSnapshot = try await householdRef.collection("settlements").getDocuments()
        for doc in settlementsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        try await batch.commit()
    }

    func deleteTransaction(transactionId: String) {
        householdRef.collection("transactions").document(transactionId).delete { error in
            if let error = error {
                print("Error deleting transaction \(transactionId): \(error.localizedDescription)")
            }
        }
    }

    func getSettlements() -> AnyPublisher<[Settlement], Error> {
        let subject = PassthroughSubject<[Settlement], Error>()

        let listener = householdRef.collection("settlements")
            .order(by: "dateMillis", descending: true)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for settlements. \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let items = snapshot.documents.compactMap { doc -> Settlement? in
                    do {
                        var s = try doc.data(as: Settlement.self)
                        s.isPending = doc.metadata.hasPendingWrites
                        return s
                    } catch {
                        print("Error decoding settlement: \(error.localizedDescription)")
                        return nil
                    }
                }
                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    func getSettlement(settlementId: String) async throws -> Settlement? {
        do {
            let doc = try await householdRef.collection("settlements").document(settlementId).getDocument()
            return try doc.data(as: Settlement.self)
        } catch {
            print("Error fetching settlement \(settlementId): \(error.localizedDescription)")
            throw error
        }
    }

    func addSettlement(_ settlement: Settlement) {
        var newSettlement = settlement
        newSettlement.createdBy = currentUserId
        do {
            try householdRef.collection("settlements").document(newSettlement.id ?? UUID().uuidString).setData(from: newSettlement)
        } catch {
            print("Error adding settlement: \(error.localizedDescription)")
        }
    }

    func updateSettlement(_ settlement: Settlement) {
        guard let id = settlement.id else {
            print("Error updating settlement: Settlement ID is nil.")
            return
        }
        do {
            try householdRef.collection("settlements").document(id).setData(from: settlement)
        } catch {
            print("Error updating settlement: \(error.localizedDescription)")
        }
    }

    func deleteSettlement(settlementId: String) {
        householdRef.collection("settlements").document(settlementId).delete { error in
            if let error = error {
                print("Error deleting settlement \(settlementId): \(error.localizedDescription)")
            }
        }
    }

    func getGoals() -> AnyPublisher<[Goal], Error> {
        let sharedGoalsSubject = PassthroughSubject<[Goal], Error>()
        let personalGoalsSubject = PassthroughSubject<[Goal], Error>()

        let sharedListener = householdRef.collection("goals")
            .whereField("personal", isEqualTo: false)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for shared goals. \(error.localizedDescription)")
                    sharedGoalsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let items = snapshot.documents.compactMap { doc -> Goal? in
                    do {
                        var g = try doc.data(as: Goal.self)
                        g.isPending = doc.metadata.hasPendingWrites
                        return g
                    } catch {
                        print("Error decoding shared goal: \(error.localizedDescription)")
                        return nil
                    }
                }
                sharedGoalsSubject.send(items)
            }

        let personalListener = householdRef.collection("goals")
            .whereField("personal", isEqualTo: true)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for personal goals. \(error.localizedDescription)")
                    personalGoalsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let items = snapshot.documents.compactMap { doc -> Goal? in
                    do {
                        var g = try doc.data(as: Goal.self)
                        g.isPending = doc.metadata.hasPendingWrites
                        return g
                    } catch {
                        print("Error decoding personal goal: \(error.localizedDescription)")
                        return nil
                    }
                }
                personalGoalsSubject.send(items)
            }

        return Publishers.CombineLatest(sharedGoalsSubject, personalGoalsSubject)
            .map { shared, personal in
                (shared + personal).sorted { $0.createdAt > $1.createdAt }
            }
            .handleEvents(receiveCancel: {
                sharedListener.remove()
                personalListener.remove()
            })
            .eraseToAnyPublisher()
    }

    func addGoal(_ goal: Goal) {
        var newGoal = goal
        if newGoal.createdBy.isEmpty {
            newGoal.createdBy = currentUserId
        }
        do {
            try householdRef.collection("goals").document(newGoal.id ?? UUID().uuidString).setData(from: newGoal)
        } catch {
            print("Error adding goal: \(error.localizedDescription)")
        }
    }

    func updateGoal(_ goal: Goal) {
        guard let id = goal.id else {
            print("Error updating goal: Goal ID is nil.")
            return
        }
        do {
            try householdRef.collection("goals").document(id).setData(from: goal)
        } catch {
            print("Error updating goal: \(error.localizedDescription)")
        }
    }

    func deleteGoal(goalId: String) {
        householdRef.collection("goals").document(goalId).delete { error in
            if let error = error {
                print("Error deleting goal \(goalId): \(error.localizedDescription)")
            }
        }
    }

    func getBudgets() -> AnyPublisher<[Budget], Error> {
        let sharedBudgetsSubject = PassthroughSubject<[Budget], Error>()
        let personalBudgetsSubject = PassthroughSubject<[Budget], Error>()

        let sharedListener = householdRef.collection("budgets")
            .whereField("personal", isEqualTo: false)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for shared budgets. \(error.localizedDescription)")
                    sharedBudgetsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let items = snapshot.documents.compactMap { doc -> Budget? in
                    do {
                        var b = try doc.data(as: Budget.self)
                        b.isPending = doc.metadata.hasPendingWrites
                        return b
                    } catch {
                        print("Error decoding shared budget: \(error.localizedDescription)")
                        return nil
                    }
                }
                sharedBudgetsSubject.send(items)
            }

        let personalListener = householdRef.collection("budgets")
            .whereField("personal", isEqualTo: true)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for personal budgets. \(error.localizedDescription)")
                    personalBudgetsSubject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let items = snapshot.documents.compactMap { doc -> Budget? in
                    do {
                        var b = try doc.data(as: Budget.self)
                        b.isPending = doc.metadata.hasPendingWrites
                        return b
                    } catch {
                        print("Error decoding personal budget: \(error.localizedDescription)")
                        return nil
                    }
                }
                personalBudgetsSubject.send(items)
            }

        return Publishers.CombineLatest(sharedBudgetsSubject, personalBudgetsSubject)
            .map { shared, personal in
                (shared + personal).sorted { $0.createdAt > $1.createdAt }
            }
            .handleEvents(receiveCancel: {
                sharedListener.remove()
                personalListener.remove()
            })
            .eraseToAnyPublisher()
    }

    func addBudget(_ budget: Budget) {
        var newBudget = budget
        if newBudget.createdBy.isEmpty {
            newBudget.createdBy = currentUserId
        }
        do {
            try householdRef.collection("budgets").document(newBudget.id ?? UUID().uuidString).setData(from: newBudget)
        } catch {
            print("Error adding budget: \(error.localizedDescription)")
        }
    }

    func updateBudget(_ budget: Budget) {
        guard let id = budget.id else {
            print("Error updating budget: Budget ID is nil.")
            return
        }
        do {
            try householdRef.collection("budgets").document(id).setData(from: budget)
        } catch {
            print("Error updating budget: \(error.localizedDescription)")
        }
    }

    func deleteBudget(budgetId: String) {
        householdRef.collection("budgets").document(budgetId).delete { error in
            if let error = error {
                print("Error deleting budget \(budgetId): \(error.localizedDescription)")
            }
        }
    }

    func getCustomCategories() -> AnyPublisher<[CustomCategory], Error> {
        let subject = PassthroughSubject<[CustomCategory], Error>()

        let listener = householdRef.collection("categories")
            .order(by: "name", descending: false)
            .addSnapshotListener(includeMetadataChanges: .include) { snapshot, error in
                if let error = error {
                    print("LedgerRepository: Listen failed for categories. \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                    return
                }
                guard let snapshot = snapshot else { return }

                let categories = snapshot.documents.compactMap { doc -> CustomCategory? in
                    do {
                        return try doc.data(as: CustomCategory.self)
                    } catch {
                        print("Error decoding custom category: \(error.localizedDescription)")
                        return nil
                    }
                }
                subject.send(categories)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    func addCustomCategory(_ category: CustomCategory) {
        do {
            try householdRef.collection("categories").document(category.id ?? UUID().uuidString).setData(from: category)
        } catch {
            print("Error adding custom category: \(error.localizedDescription)")
        }
    }

    func deleteCustomCategory(categoryId: String) {
        householdRef.collection("categories").document(categoryId).delete { error in
            if let error = error {
                print("Error deleting custom category \(categoryId): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Model Stubs (Assumed to be defined elsewhere and conform to Codable & Identifiable)
// These are placeholders for the actual model definitions.
// In a real project, these would be in separate files or a dedicated Models.swift file.

// struct Transaction: Codable, Identifiable {
//     @DocumentID var id: String? = UUID().uuidString
//     var dateMillis: Date // Use Date for timestamps
//     var amount: Double
//     var description: String
//     var category: String
//     var personal: Bool
//     var createdBy: String
//     var isDeleted: Bool? = false
//     var isPending: Bool = false // Mutable for metadata
//     // Add other properties as needed
// }

// struct Settlement: Codable, Identifiable {
//     @DocumentID var id: String? = UUID().uuidString
//     var dateMillis: Date
//     var amount: Double
//     var description: String
//     var createdBy: String
//     var isPending: Bool = false
//     // Add other properties as needed
// }

// struct Goal: Codable, Identifiable {
//     @DocumentID var id: String? = UUID().uuidString
//     var name: String
//     var targetAmount: Double
//     var currentAmount: Double
//     var createdAt: Date
//     var personal: Bool
//     var createdBy: String
//     var isPending: Bool = false
//     // Add other properties as needed
// }

// struct Budget: Codable, Identifiable {
//     @DocumentID var id: String? = UUID().uuidString
//     var name: String
//     var amount: Double
//     var createdAt: Date
//     var personal: Bool
//     var createdBy: String
//     var isPending: Bool = false
//     // Add other properties as needed
// }

// struct CustomCategory: Codable, Identifiable {
//     @DocumentID var id: String? = UUID().uuidString
//     var name: String
//     // Add other properties as needed
// }