import Fluent
import Vapor
import WebAuthn

/// A `WebAuthnCredential` represents a WebAuthn credential stored in a database.
///
/// This class is designed to work with Fluent for ORM support, allowing the storage and retrieval
/// of WebAuthn credentials associated with a user. It includes properties for the credential's
/// unique identifier, public key, current signature count, associated user, and creation timestamp.
public final class WebAuthnCredential: Model, Content {
    /// The schema name for the `WebAuthnCredential` model.
    ///
    /// This is used by Fluent to map the `WebAuthnCredential` class to a database table named `webauth_credentals`.
    public static let schema = "webauth_credentals"

    /// The unique identifier for the credential.
    ///
    /// This property is marked with `@ID` to denote it as the primary key in the database.
    /// It is custom-set to be generated by the user, meaning it must be provided upon creation.
    @ID(custom: "id", generatedBy: .user)
    public var id: String?

    /// The public key of the credential.
    ///
    /// This key is used in the authentication process to verify the user's identity.
    @Field(key: "public_key")
    public var publicKey: String

    /// The current signature count of the credential.
    ///
    /// This count is used to prevent replay attacks by ensuring that each authentication
    /// signature is unique.
    @Field(key: "current_sign_count")
    public var currentSignCount: Int

    /// The associated user of the credential.
    ///
    /// This property establishes a relationship between the credential and a `PasskeyUser`,
    /// indicating which user the credential belongs to.
    @Parent(key: "passkey_user_id")
    public var user: PasskeyUser

    /// The timestamp of when the credential was created.
    ///
    /// This property is automatically set to the current date and time when a new credential
    /// entity is created, thanks to the `@Timestamp` property wrapper.
    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    /// Initializes a new `WebAuthnCredential`.
    ///
    /// This initializer is required for conforming to `Fluent.Model`.
    public init() {}

    /// Initializes a new `WebAuthnCredential` with the specified properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the credential.
    ///   - publicKey: The public key of the credential.
    ///   - currentSignCount: The current signature count of the credential.
    ///   - username: The username of the associated `PasskeyUser`.
    public init(id: String, publicKey: String, currentSignCount: UInt32, username: String) {
        self.id = id
        self.publicKey = publicKey
        self.currentSignCount = Int(currentSignCount)
        self.$user.id = username
    }

    /// Convenience initializer to create a `WebAuthnCredential` from a `Credential` object and a username.
    ///
    /// This initializer is useful for creating a `WebAuthnCredential` directly from the data obtained
    /// during the registration or authentication process.
    ///
    /// - Parameters:
    ///   - credential: A `Credential` object containing the credential's data.
    ///   - username: The username of the associated `PasskeyUser`.
    public convenience init(from credential: Credential, username: String) {
        self.init(
            id: credential.id,
            publicKey: credential.publicKey.base64URLEncodedString().asString(),
            currentSignCount: credential.signCount,
            username: username
        )
    }
}
