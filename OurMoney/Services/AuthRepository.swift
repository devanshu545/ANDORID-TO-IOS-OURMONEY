import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// Assuming AuthState, User, and Household are defined in separate files as Swift structs/enums.
// For the purpose of this conversion, I'll include their basic definitions here.
// You should move these to their respective model files.

// MARK: - AuthState (Enum)
enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(User, Household)
    case requiresName(String) // uid
    case requiresPairing(User, Household?, String?) // user, household (if partially paired), errorMessage
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case let (.authenticated(user1, household1), .authenticated(user2, household2)):
            return user1.id == user2.id && household1.id == household2.id
        case let (.requiresName(uid1), .requiresName(uid2)):
            return uid1 == uid2
        case let (.requiresPairing(user1, household1, error1), .requiresPairing(user2, household2, error2)):
            return user1.id == user2.id && household1?.id == household2?.id && error1 == error2
        case let (.error(msg1), .error(msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

// MARK: - User (Struct)
struct User: Codable, Identifiable, Equatable {
    @DocumentID var id: String? // FirebaseFirestore uses @DocumentID for the document ID
    var name: String
    var email: String
    var householdId: String?
    var connectedAt: Date? // Changed from Long to Date for Swift

    // Custom initializer for creating a new user
    init(id: String, name: String, email: String, householdId: String? = nil, connectedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.householdId = householdId
        self.connectedAt = connectedAt
    }

    // Default initializer for Firestore decoding
    init() {
        self.id = nil
        self.name = ""
        self.email = ""
        self.householdId = nil
        self.connectedAt = nil
    }
}

// MARK: - Household (Struct)
struct Household: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var code: String
    var members: [String] // Array of user IDs

    // Custom initializer for creating a new household
    init(id: String, code: String, members: [String]) {
        self.id = id
        self.code = code
        self.members = members
    }

    // Default initializer for Firestore decoding
    init() {
        self.id = nil
        self.code = ""
        self.members = []
    }
}

// MARK: - AuthRepository (Class)
class AuthRepository: ObservableObject {
    @Published private var _authState: AuthState = .idle
    var authState: AnyPublisher<AuthState, Never> {
        $_authState.eraseToAnyPublisher()
    }

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    private var householdListener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateDidChangeListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
        userListener?.remove()
        householdListener?.remove()
    }

    private func setupAuthStateListener() {
        authStateDidChangeListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.checkCurrentUser(uid: user.uid)
            } else {
                self.userListener?.remove()
                self.userListener = nil
                self.householdListener?.remove()
                self.householdListener = nil
                self._authState = .idle
            }
        }
    }

    func signInWithGoogle(idToken: String) async {
        _authState = .loading
        do {
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: nil)
            _ = try await auth.signIn(with: credential)
            // AuthStateListener will handle the state update
        } catch {
            _authState = .error(error.localizedDescription)
            print("AuthRepository: Google Sign-In failed: \(error.localizedDescription)")
        }
    }

    private func checkCurrentUser(uid: String) {
        _authState = .loading
        userListener?.remove()
        userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                self._authState = .error(error.localizedDescription)
                print("AuthRepository: Failed to load user: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                do {
                    let user = try snapshot.data(as: User.self)
                    if let householdId = user.householdId, !householdId.isEmpty {
                        self.listenToHousehold(user: user)
                    } else {
                        self.householdListener?.remove()
                        self.householdListener = nil
                        self._authState = .requiresPairing(user, nil, nil)
                    }
                } catch {
                    print("AuthRepository: Failed to parse User: \(error.localizedDescription)")
                    self._authState = .error("Failed to parse user data.")
                }
            } else {
                self._authState = .requiresName(uid)
            }
        }
    }

    private func listenToHousehold(user: User) {
        guard let householdId = user.householdId else {
            _authState = .requiresPairing(user, nil, nil)
            return
        }

        householdListener?.remove()
        householdListener = db.collection("households").document(householdId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                self._authState = .error(error.localizedDescription)
                print("AuthRepository: Failed to load household: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                do {
                    let household = try snapshot.data(as: Household.self)
                    guard let userId = user.id else {
                        self._authState = .error("User ID is missing.")
                        return
                    }

                    if !household.members.contains(userId) {
                        // We are no longer in this household, clear state
                        Task {
                            try await self.db.collection("users").document(userId).updateData(["householdId": FieldValue.delete()])
                            self._authState = .requiresPairing(user, nil, nil)
                        }
                    } else if household.members.count < 2 {
                        self._authState = .requiresPairing(user, household, nil)
                    } else {
                        self._authState = .authenticated(user, household)
                    }
                } catch {
                    print("AuthRepository: Failed to parse Household: \(error.localizedDescription)")
                    self._authState = .error("Failed to parse household data.")
                }
            } else {
                // Household doesn't exist anymore, clear it from user
                guard let userId = user.id else {
                    self._authState = .error("User ID is missing.")
                    return
                }
                Task {
                    try await self.db.collection("users").document(userId).updateData(["householdId": FieldValue.delete()])
                    self._authState = .requiresPairing(user, nil, nil)
                }
            }
        }
    }

    func saveName(name: String) async {
        guard let uid = auth.currentUser?.uid else { return }
        _authState = .loading
        do {
            let user = User(
                id: uid,
                name: name,
                email: auth.currentUser?.email ?? ""
            )
            try await db.collection("users").document(uid).setData(from: user)
            // AuthStateListener will pick up the change and update state
        } catch {
            _authState = .error(error.localizedDescription)
            print("AuthRepository: Failed to save name: \(error.localizedDescription)")
        }
    }

    func createHousehold(user: User) async {
        guard let userId = user.id else {
            _authState = .requiresPairing(user, nil, "User ID is missing.")
            return
        }
        _authState = .loading
        do {
            let code = String(format: "%06d", Int.random(in: 100000...999999))
            let householdRef = db.collection("households").document() // Let Firestore generate ID
            let householdId = householdRef.documentID

            let household = Household(
                id: householdId,
                code: code,
                members: [userId]
            )

            try await householdRef.setData(from: household)

            var updatedUser = user
            updatedUser.householdId = household.id
            updatedUser.connectedAt = Date() // Use Date() for current time

            try await db.collection("users").document(userId).setData(from: updatedUser)
            // AuthStateListener will pick up the change and update state
        } catch {
            print("AuthRepository: Error creating household: \(error.localizedDescription)")
            _authState = .requiresPairing(user, nil, "Unable to connect. Check your internet connection and try again.")
        }
    }

    func joinHousehold(user: User, code: String) async {
        guard let userId = user.id else {
            _authState = .requiresPairing(user, nil, "User ID is missing.")
            return
        }
        _authState = .loading
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let querySnapshot = try await db.collection("households").whereField("code", isEqualTo: trimmedCode).getDocuments()

            guard let householdDoc = querySnapshot.documents.first else {
                _authState = .requiresPairing(user, nil, "Invalid connection code.")
                return
            }

            var household = try householdDoc.data(as: Household.self)

            if household.members.count >= 2 && !household.members.contains(userId) {
                _authState = .requiresPairing(user, nil, "This connection already has two members.")
                return
            }

            var updatedMembers = household.members
            if !updatedMembers.contains(userId) {
                updatedMembers.append(userId)
            }

            try await db.collection("households").document(household.id!).updateData(["members": updatedMembers])

            var updatedUser = user
            updatedUser.householdId = household.id
            updatedUser.connectedAt = Date() // Use Date() for current time

            try await db.collection("users").document(userId).setData(from: updatedUser)
            // AuthStateListener will pick up the change and update state
        } catch {
            print("AuthRepository: Error joining household: \(error.localizedDescription)")
            _authState = .requiresPairing(user, nil, "Unable to connect. Check your internet connection and try again.")
        }
    }

    func cancelPairing(user: User) async {
        guard let userId = user.id else {
            _authState = .requiresPairing(user, nil, "User ID is missing.")
            return
        }
        _authState = .loading
        do {
            let oldHouseholdId = user.householdId

            var updatedUser = user
            updatedUser.householdId = nil
            updatedUser.connectedAt = nil

            try await db.collection("users").document(userId).setData(from: updatedUser)

            if let householdIdToDelete = oldHouseholdId {
                try await db.collection("households").document(householdIdToDelete).delete()
            }
            // AuthStateListener will pick up the change and update state
        } catch {
            print("AuthRepository: Failed to cancel pairing: \(error.localizedDescription)")
            _authState = .requiresPairing(user, nil, "Failed to cancel connection.")
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            userListener?.remove()
            userListener = nil
            householdListener?.remove()
            householdListener = nil
            _authState = .idle
        } catch {
            print("AuthRepository: Error signing out: \(error.localizedDescription)")
            // Optionally, set an error state if sign out itself fails
        }
    }
}