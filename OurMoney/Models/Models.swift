enum TransactionType: String, Codable {
    case expense = "EXPENSE"
    case income = "INCOME"
    case transfer = "TRANSFER"
}

enum SplitMethod: String, Codable {
    case equal = "EQUAL"
    case exact = "EXACT"
    case percentage = "PERCENTAGE"
    case shares = "SHARES"
}

struct SplitAmount: Codable, Identifiable {
    let id = UUID().uuidString // Added for SwiftUI Identifiable conformance
    var userId: String = ""
    var amountPaise: Int64 = 0
}

struct Transaction: Codable, Identifiable {
    var id: String = UUID().uuidString
    var amountPaise: Int64 = 0
    var category: String = ""
    var dateMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var paidBy: String = ""
    var createdBy: String = ""
    var personal: Bool = false
    var splitMethod: SplitMethod = .equal
    var splits: [SplitAmount] = []
    var notes: String = ""
    var type: TransactionType = .expense
    var paymentMethod: String = "UPI"
    var isDeleted: Bool = false
    var isPending: Bool = false // Excluded from Firebase in Kotlin, treated as transient in Swift
}

struct User: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var email: String = ""
    var householdId: String? = nil
    var connectedAt: Int64? = nil
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
}

struct Household: Codable, Identifiable {
    var id: String = UUID().uuidString
    var code: String = ""
    var members: [String] = []
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
}

struct Settlement: Codable, Identifiable {
    var id: String = UUID().uuidString
    var amountPaise: Int64 = 0
    var paidBy: String = ""
    var receivedBy: String = ""
    var dateMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var paymentMethod: String = ""
    var notes: String = ""
    var createdBy: String = ""
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var isPending: Bool = false // Excluded from Firebase in Kotlin, treated as transient in Swift
}

struct Goal: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var targetAmountPaise: Int64 = 0
    var currentAmountPaise: Int64 = 0
    var personal: Bool = false
    var createdBy: String = ""
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var isPending: Bool = false // Excluded from Firebase in Kotlin, treated as transient in Swift
}

struct Budget: Codable, Identifiable {
    var id: String = UUID().uuidString
    var category: String = ""
    var limitAmountPaise: Int64 = 0
    var personal: Bool = false
    var createdBy: String = ""
    var monthYear: String = ""
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var isPending: Bool = false // Excluded from Firebase in Kotlin, treated as transient in Swift
}

struct CustomCategory: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var createdBy: String = ""
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
}

enum AiScope: String, Codable {
    case personal = "PERSONAL"
    case shared = "SHARED"
}

struct AiChat: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String = "New Conversation"
    var createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var ownerId: String = ""
    var householdId: String = ""
    var scope: AiScope = .personal
}

enum AiMessageRole: String, Codable {
    case user = "USER"
    case model = "MODEL"
    case system = "SYSTEM"
}

struct AiMessage: Codable, Identifiable {
    var id: String = UUID().uuidString
    var chatId: String = ""
    var role: AiMessageRole = .user
    var content: String = ""
    var timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
}