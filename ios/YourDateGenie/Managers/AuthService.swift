import Auth
import Foundation
import Supabase

enum AuthServiceError: LocalizedError {
    case invalidEmail
    case auth(AuthError)
    case network(String)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .auth(let error):
            return error.localizedDescription
        case .network(let message):
            return message
        case .unexpected(let message):
            return message
        }
    }
}

/// Email/password authentication via Supabase Auth (`SupabaseManager.shared.client`).
final class AuthService {
    static let shared = AuthService()

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @discardableResult
    func signUp(email: String, password: String) async throws -> Auth.AuthResponse {
        let email = normalizedEmail(email)
        guard !email.isEmpty else { throw AuthServiceError.invalidEmail }
        do {
            return try await client.auth.signUp(email: email, password: password)
        } catch let error as AuthError {
            throw AuthServiceError.auth(error)
        } catch {
            throw Self.mapNonAuthError(error)
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> Auth.Session {
        let email = normalizedEmail(email)
        guard !email.isEmpty else { throw AuthServiceError.invalidEmail }
        do {
            return try await client.auth.signIn(email: email, password: password)
        } catch let error as AuthError {
            throw AuthServiceError.auth(error)
        } catch {
            throw Self.mapNonAuthError(error)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch let error as AuthError {
            throw AuthServiceError.auth(error)
        } catch {
            throw Self.mapNonAuthError(error)
        }
    }

    private static func mapNonAuthError(_ error: Error) -> AuthServiceError {
        if let urlError = error as? URLError {
            return .network(urlError.localizedDescription)
        }
        return .unexpected(error.localizedDescription)
    }
}
