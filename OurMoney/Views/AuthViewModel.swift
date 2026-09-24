import Foundation
import Combine

class AuthViewModel: ObservableObject {
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()

    @Published var authState: AuthState = .idle

    init(authRepository: AuthRepository = AuthRepository.shared) {
        self.authRepository = authRepository

        authRepository.authState
            .receive(on: DispatchQueue.main)
            .assign(to: \.authState, on: self)
            .store(in: &cancellables)
    }

    func signInWithGoogle(idToken: String) {
        Task {
            await authRepository.signInWithGoogle(idToken)
        }
    }

    func saveName(name: String) {
        Task {
            await authRepository.saveName(name)
        }
    }

    func createHousehold(user: User, onCreated: @escaping (String) -> Void) {
        Task {
            await authRepository.createHousehold(user: user, onCreated: onCreated)
        }
    }

    func joinHousehold(user: User, code: String) {
        Task {
            await authRepository.joinHousehold(user: user, code: code)
        }
    }

    func cancelPairing(user: User) {
        Task {
            await authRepository.cancelPairing(user: user)
        }
    }

    func signOut() {
        authRepository.signOut()
    }
}