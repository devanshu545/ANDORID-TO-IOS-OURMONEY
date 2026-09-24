import SwiftUI
import GoogleSignIn // Ensure GoogleSignIn SDK is integrated into your Xcode project

// MARK: - Models (Assuming these models exist in your project)

// Define basic User and Household structs if they are not already defined elsewhere.
// They should conform to Identifiable and Hashable for SwiftUI compatibility.
struct User: Identifiable, Hashable {
    let id: String // Unique identifier for the user
    var name: String
    // Add other user-specific properties as needed
}

struct Household: Identifiable, Hashable {
    let id: String // Unique identifier for the household
    var code: String // The pairing code
    var members: [User] // List of members in the household
    // Add other household-specific properties as needed
}

// MARK: - AuthViewModel (Mock implementation for conversion)

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var currentHousehold: Household?
    @Published var pairingError: String?
    @Published var isLoading: Bool = false // General loading state for the ViewModel

    // Simulates signing in with Google ID token
    func signInWithGoogle(_ idToken: String) {
        print("AuthViewModel: Signing in with Google ID Token: \(idToken)")
        isLoading = true
        // Simulate a network call or authentication process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentUser = User(id: "google-user-\(UUID().uuidString)", name: "New User")
            self.isLoading = false
            print("AuthViewModel: Google Sign-In successful for user: \(self.currentUser?.name ?? "N/A")")
        }
    }

    // Simulates saving the user's name
    func saveName(_ name: String) {
        print("AuthViewModel: Saving name: \(name)")
        if var user = currentUser {
            user.name = name
            self.currentUser = user
            print("AuthViewModel: User name updated to: \(user.name)")
        }
    }

    // Simulates joining an existing household
    func joinHousehold(_ user: User, _ code: String) {
        print("AuthViewModel: User \(user.name) attempting to join household with code: \(code)")
        isLoading = true
        pairingError = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if code.uppercased() == "VALIDCODE" { // Example valid code
                let partner = User(id: "partner-\(UUID().uuidString)", name: "Partner")
                self.currentHousehold = Household(id: "hh-\(UUID().uuidString)", code: code, members: [user, partner])
                print("AuthViewModel: User \(user.name) successfully joined household \(code)")
            } else {
                self.pairingError = "Invalid connection code. Please try again."
                print("AuthViewModel: Failed to join household: Invalid code.")
            }
            self.isLoading = false
        }
    }

    // Simulates creating a new household
    func createHousehold(_ user: User, completion: @escaping (Household?) -> Void) {
        print("AuthViewModel: User \(user.name) attempting to create a new household.")
        isLoading = true
        pairingError = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
            let newHousehold = Household(id: "new-hh-\(UUID().uuidString)", code: newCode, members: [user])
            self.currentHousehold = newHousehold
            self.isLoading = false
            print("AuthViewModel: User \(user.name) created new household with code: \(newCode)")
            completion(newHousehold)
        }
    }

    // Simulates cancelling a pairing process
    func cancelPairing(_ user: User) {
        print("AuthViewModel: User \(user.name) cancelling pairing.")
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentHousehold = nil
            self.pairingError = nil
            self.isLoading = false
            print("AuthViewModel: Pairing cancelled.")
        }
    }

    // Simulates signing out
    func signOut() {
        print("AuthViewModel: Signing out.")
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            GIDSignIn.sharedInstance.signOut() // Sign out from Google as well
            self.currentUser = nil
            self.currentHousehold = nil
            self.pairingError = nil
            self.isLoading = false
            print("AuthViewModel: User signed out.")
        }
    }
}

// MARK: - Helper to find the top-most UIViewController for Google Sign-In

extension View {
    func getRootViewController() -> UIViewController? {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        guard let root = screen.windows.first?.rootViewController else {
            return nil
        }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}

// MARK: - GoogleSignInScreen

struct GoogleSignInScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Replace with your actual Google Cloud Console client ID for iOS
    private let serverClientId = "1043186572321-18em4e4netpcsicep9q0tdgojo0i99r9.apps.googleusercontent.com"

    var body: some View {
        VStack(alignment: .center) {
            Text("Welcome to OurMoney")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer().frame(height: 8)
            Text("Cloud Sync requires a Google Account.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 32)

            if isLoading || viewModel.isLoading {
                ProgressView()
            } else {
                Button {
                    isLoading = true
                    errorMessage = nil
                    signInWithGoogle()
                } label: {
                    Text("Sign in with Google")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent) // Primary action button style
                .frame(maxWidth: .infinity, minHeight: 56)
            }

            if let errorMessage = errorMessage {
                Spacer().frame(height: 16)
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func signInWithGoogle() {
        guard let presentingViewController = getRootViewController() else {
            errorMessage = "Could not find presenting view controller for Google Sign-In."
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: serverClientId)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Google Sign-In error: \(error.localizedDescription)")
                    if let signInError = error as? GIDSignInError {
                        switch signInError.code {
                        case .canceled:
                            errorMessage = "Sign in cancelled."
                        case .noSignInHandlersInstalled:
                            errorMessage = "Google Sign-In is not configured correctly. Check URL schemes and client ID."
                        case .hasNoAuthInKeychain:
                            errorMessage = "No Google account found. Please add an account in iOS Settings or Google app."
                        default:
                            errorMessage = "Sign in failed: \(error.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Sign in failed: \(error.localizedDescription)"
                    }
                } else if let result = signInResult {
                    if let idToken = result.user.idToken?.tokenString {
                        viewModel.signInWithGoogle(idToken)
                    } else {
                        errorMessage = "Failed to get Google ID Token."
                    }
                } else {
                    errorMessage = "Unknown Google Sign-In error."
                }
            }
        }
    }
}

// MARK: - NameInputScreen

struct NameInputScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var name: String = ""

    var body: some View {
        VStack(alignment: .center) {
            Text("What should we call you?")
                .font(.headline)
                .fontWeight(.bold)
            Spacer().frame(height: 24)
            TextField("Your Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
            Spacer().frame(height: 24)
            Button {
                if !name.isEmpty {
                    viewModel.saveName(name)
                }
            } label: {
                Text("Save Name")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty || viewModel.isLoading)
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PairingScreen

struct PairingScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let user: User // User is passed directly
    let household: Household? // Household is passed directly
    let error: String? // Error is passed directly (from ViewModel's pairingError)

    @State private var inputCode: String = ""

    var body: some View {
        VStack(alignment: .center) {
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.body)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 16)
            }

            Text("Connect with your partner")
                .font(.headline)
                .fontWeight(.bold)
            Spacer().frame(height: 8)
            Text("Create a new connection or join an existing one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer().frame(height: 48)

            if let household = household {
                Text("Share this code with your partner:")
                    .font(.body)
                Spacer().frame(height: 16)
                Text(household.code)
                    .font(.largeTitle) // Equivalent to MaterialTheme.typography.displayMedium
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                Spacer().frame(height: 16)
                Text("Waiting for your friend to join")
                    .font(.body)
                Spacer().frame(height: 8)
                Text("Members: \(household.members.count) / 2")
                    .font(.body)
                Spacer().frame(height: 8)
                Text("Your Name: \(user.name)")
                    .font(.body)
                Spacer().frame(height: 32)
                Button("Cancel Connection") {
                    viewModel.cancelPairing(user)
                }
                .buttonStyle(.bordered) // Equivalent to OutlinedButton
                .disabled(viewModel.isLoading)
            } else {
                Text("Your Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(user.name)
                    .font(.body)
                    .fontWeight(.bold)
                Spacer().frame(height: 24)

                TextField("Connection Code", text: $inputCode)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                Spacer().frame(height: 16)
                Button("Join Connection") {
                    if !inputCode.isEmpty {
                        viewModel.joinHousehold(user, inputCode)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputCode.isEmpty || viewModel.isLoading)
                .frame(maxWidth: .infinity, minHeight: 56)

                Spacer().frame(height: 32)
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer().frame(height: 32)

                Button("Create New Connection") {
                    viewModel.createHousehold(user) { _ in
                        // Handle completion if needed, e.g., navigate or show success
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
                .frame(maxWidth: .infinity, minHeight: 56)
                Spacer().frame(height: 32)
                Button("Sign out") {
                    viewModel.signOut()
                }
                .buttonStyle(.plain) // Equivalent to TextButton
                .disabled(viewModel.isLoading)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}