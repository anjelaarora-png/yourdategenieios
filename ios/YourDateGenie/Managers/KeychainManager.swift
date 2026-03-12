import Foundation
import Security

/// A secure wrapper for storing sensitive data in the iOS Keychain
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = Bundle.main.bundleIdentifier ?? "com.yourdategenie.app"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Save a string value to keychain
    func save(_ value: String, forKey key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: key)
    }
    
    /// Save data to keychain
    func save(_ data: Data, forKey key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// Retrieve a string value from keychain
    func getString(forKey key: KeychainKey) throws -> String? {
        guard let data = try getData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Retrieve data from keychain
    func getData(forKey key: KeychainKey) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        return result as? Data
    }
    
    /// Delete a value from keychain
    func delete(forKey key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Delete all items for this service
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Check if a key exists in keychain
    func exists(forKey key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Codable Support
    
    /// Save a Codable object to keychain
    func save<T: Encodable>(_ object: T, forKey key: KeychainKey) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, forKey: key)
    }
    
    /// Retrieve a Codable object from keychain
    func get<T: Decodable>(_ type: T.Type, forKey key: KeychainKey) throws -> T? {
        guard let data = try getData(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Keychain Keys

enum KeychainKey: String {
    case userIdToken = "user_id_token"
    case userRefreshToken = "user_refresh_token"
    case userEmail = "user_email"
    case userUID = "user_uid"
    case sessionData = "session_data"
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for keychain storage"
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}

// MARK: - Secure Session Storage

struct SecureSession: Codable {
    let userId: String
    let email: String
    let idToken: String?
    let refreshToken: String?
    let expiresAt: Date?
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

extension KeychainManager {
    
    /// Save user session securely
    func saveSession(_ session: SecureSession) throws {
        try save(session, forKey: .sessionData)
        try save(session.userId, forKey: .userUID)
        try save(session.email, forKey: .userEmail)
        if let idToken = session.idToken {
            try save(idToken, forKey: .userIdToken)
        }
        if let refreshToken = session.refreshToken {
            try save(refreshToken, forKey: .userRefreshToken)
        }
    }
    
    /// Retrieve user session
    func getSession() throws -> SecureSession? {
        return try get(SecureSession.self, forKey: .sessionData)
    }
    
    /// Clear user session
    func clearSession() throws {
        try delete(forKey: .sessionData)
        try delete(forKey: .userUID)
        try delete(forKey: .userEmail)
        try delete(forKey: .userIdToken)
        try delete(forKey: .userRefreshToken)
    }
}
