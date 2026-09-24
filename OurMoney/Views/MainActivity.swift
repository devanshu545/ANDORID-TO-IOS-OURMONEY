import SwiftUI
import Combine

// MARK: - App Entry Point
@main
struct OurMoneyApp: App {
    // Initialize the AuthViewModel as a StateObject to own its lifecycle
    @StateObject private var authViewModel = AuthViewModel()

    // Observe the scenePhase to track app foreground/background state
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // The ContentView is the root of our application's UI
            ContentView()
                // Make the AuthViewModel available to all child views in the environment
                .environmentObject(authViewModel)
                // React to changes in the app's scene phase
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        AppForegroundTracker.isAppInForeground = true
                    case .inactive, .background:
                        AppForegroundTracker.isAppInForeground = false
                    @unknown default:
                        // Handle future unknown cases gracefully
                        break
                    }
                }
        }
    }
}

// MARK: - Root Content View (Equivalent to OurMoneyApp Composable)
struct ContentView: View {
    // Access the AuthViewModel from the environment
    @EnvironmentObject var authViewModel: AuthViewModel
    // Local state to control the initial splash screen visibility
    @State private var showInitialSplash: Bool = true

    var body: some View {
        // Use a ZStack to layer views, similar to Compose's Box or Surface
        ZStack {
            // Mimics MaterialTheme.colorScheme.background, using a clear color or a specific app background
            Color.clear.ignoresSafeArea() // Or a specific background color like Color.white

            if showInitialSplash {
                // Show the initial splash screen
                SplashScreen()
            } else {
                // Once the initial splash is done, show content based on authentication state
                switch authViewModel.authState {
                case .loading:
                    // Show splash screen while authentication state is loading
                    SplashScreen()
                case .idle:
                    // User needs to sign in
                    GoogleSignInScreen()
                case .requiresName:
                    // User needs to input their name
                    NameInputScreen()
                case .requiresPairing(let user, let household, let error):
                    // User needs to complete pairing
                    PairingScreen(user: user, household: household, error: error)
                case .authenticated(let user, let household):
                    // User is authenticated, show the main application screen
                    MainScreen(user: user, household: household)
                case .error(let message):
                    // Display an error message
                    VStack {
                        Text("Error: \(message)")
                            .foregroundColor(.red) // Equivalent to MaterialTheme.colorScheme.error
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear) // Ensure background is clear or matches app theme
                }
            }
        }
        .onAppear {
            // Simulate a delay for the initial splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showInitialSplash = false
            }
        }
    }
}

// MARK: - Models

/// Represents a user in the application.
struct User: Identifiable, Equatable {
    let id: String
    let name: String
    // Add other user-specific properties as needed
}

/// Represents a household in the application.
struct Household: Identifiable, Equatable {
    let id: String
    let name: String
    // Add other household-specific properties as needed
}

// MARK: - Authentication State

/// Defines the various states of the authentication flow.
enum AuthState: Equatable {
    case loading
    case idle // User needs to initiate sign-in
    case requiresName
    case requiresPairing(user: User, household: Household, error: String?)
    case authenticated(user: User, household: Household)
    case error(message: String)
}

// MARK: - View Model

/// Manages the authentication state and business logic.
class AuthViewModel: ObservableObject {
    // @Published property to notify SwiftUI views of changes in authentication state
    @Published var authState: AuthState = .loading

    init() {
        // Simulate an asynchronous authentication process
        // In a real app, this would involve network calls, token checks, etc.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Example: Transition to an idle state after initial loading
            // For demonstration, we'll simulate a successful authentication after a delay.
            // In a real app, this would be determined by actual auth logic.
            let sampleUser = User(id: UUID().uuidString, name: "John Doe")
            let sampleHousehold = Household(id: UUID().uuidString, name: "Doe Family")
            self.authState = .authenticated(user: sampleUser, household: sampleHousehold)
            // To test other states, uncomment one of the following:
            // self.authState = .idle
            // self.authState = .requiresName
            // self.authState = .requiresPairing(user: sampleUser, household: sampleHousehold, error: nil)
            // self.authState = .error(message: "Failed to connect to server.")
        }
    }

    // Example methods for authentication actions
    func signInWithGoogle() {
        print("Attempting Google Sign-In...")
        // Simulate sign-in process
        authState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newUser = User(id: UUID().uuidString, name: "New User")
            let newHousehold = Household(id: UUID().uuidString, name: "New Household")
            self.authState = .requiresName // Or .authenticated, .requiresPairing based on backend response
        }
    }

    func submitName(name: String) {
        print("Submitting name: \(name)")
        authState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let userWithName = User(id: UUID().uuidString, name: name)
            let householdForUser = Household(id: UUID().uuidString, name: "\(name)'s Household")
            self.authState = .requiresPairing(user: userWithName, household: householdForUser, error: nil)
        }
    }

    func completePairing(user: User, household: Household) {
        print("Completing pairing for \(user.name) with \(household.name)")
        authState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.authState = .authenticated(user: user, household: household)
        }
    }
}

// MARK: - App Foreground Tracker

/// A simple class to track if the application is in the foreground.
class AppForegroundTracker {
    static var isAppInForeground: Bool = false
}

// MARK: - UI Components

/// A custom SwiftUI view that mimics a Material Design CircularProgressIndicator.
struct CircularProgressIndicator: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7) // Creates an arc
            .stroke(Color.accentColor, lineWidth: 4) // Stroke with accent color
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0)) // Rotate indefinitely
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true // Start animation when view appears
            }
    }
}

/// Displays a splash screen with a loading indicator.
struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Use a background color that fits your app's theme
            Color.blue.ignoresSafeArea() // Example background color
            VStack {
                Image(systemName: "hourglass") // Example system icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                Text("OurMoney")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                CircularProgressIndicator()
                    .padding(.top, 20)
            }
        }
    }
}

/// Screen for Google Sign-In.
struct GoogleSignInScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to OurMoney")
                .font(.title)
                .padding(.bottom, 20)

            Button {
                authViewModel.signInWithGoogle()
            } label: {
                Label("Sign In with Google", systemImage: "g.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // Or your app's background color
    }
}

/// Screen for user to input their name.
struct NameInputScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.title)
                .padding(.bottom, 20)

            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Continue") {
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    authViewModel.submitName(name: name)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// Screen for pairing with a household.
struct PairingScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let user: User
    let household: Household
    let error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Pairing with Household")
                .font(.title)
                .padding(.bottom, 10)

            Text("User: \(user.name)")
                .font(.headline)
            Text("Household: \(household.name)")
                .font(.headline)

            if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Complete Pairing") {
                authViewModel.completePairing(user: user, household: household)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// The main application screen after successful authentication.
struct MainScreen: View {
    let user: User
    let household: Household

    var body: some View {
        // In a real app, this would be a TabView or NavigationStack
        // leading to various features.
        VStack(spacing: 20) {
            Text("Welcome to OurMoney!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.green)

            Text("Hello, \(user.name)!")
                .font(.title2)
            Text("You are part of the \(household.name) household.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer() // Pushes content to the top
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}