import Foundation
import Combine
import AuthenticationServices

class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userID: String?
    @Published var displayName: String?

    private let userIDKey = "beUserID"
    private let displayNameKey = "beDisplayName"

    init() {
        if let storedID = UserDefaults.standard.string(forKey: userIDKey) {
            userID = storedID
            displayName = UserDefaults.standard.string(forKey: displayNameKey)
            isSignedIn = true
        }
    }

    func signIn(credential: ASAuthorizationAppleIDCredential) {
        let id = credential.user
        userID = id
        UserDefaults.standard.set(id, forKey: userIDKey)

        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                displayName = name
                UserDefaults.standard.set(name, forKey: displayNameKey)
            }
        }

        isSignedIn = true
    }

    // TODO: Remove this when real Sign in with Apple is set up
    func continueWithoutAuth() {
        userID = "local-user"
        UserDefaults.standard.set(userID, forKey: userIDKey)
        isSignedIn = true
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        userID = nil
        displayName = nil
        isSignedIn = false
    }
}
