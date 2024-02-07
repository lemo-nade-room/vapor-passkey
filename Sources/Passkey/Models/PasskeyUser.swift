import Fluent
import Vapor
import WebAuthn

/// A `PasskeyUser` represents a user entity in a database that can be authenticated using passkeys.
///
/// This class is designed to work with Fluent for ORM support and integrates with WebAuthn for authentication.
/// It includes properties for user identification, display name, and creation timestamp.
public final class PasskeyUser: Fluent.Model {
    /// The schema name for the `PasskeyUser` model.
    ///
    /// This is used by Fluent to map the `PasskeyUser` class to a database table named `passkey_users`.
    public static let schema = "passkey_users"

    /// The unique identifier for the user, typically a username.
    ///
    /// This property is marked with `@ID` to denote it as the primary key in the database.
    /// It is custom-set to be generated by the user, meaning it must be provided upon creation.
    @ID(custom: "username", generatedBy: .user)
    public var id: String?

    /// The display name of the user.
    ///
    /// This property is stored in the database under the key `display_name` and represents
    /// a name that can be shown in user interfaces.
    @Field(key: "display_name")
    public var displayName: String

    /// The timestamp of when the user was created.
    ///
    /// This property is automatically set to the current date and time when a new user entity is created,
    /// thanks to the `@Timestamp` property wrapper.
    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    /// Initializes a new `PasskeyUser`.
    ///
    /// This initializer is required for conforming to `Fluent.Model`.
    public init() {}

    /// Initializes a new `PasskeyUser` with a username and an optional display name.
    ///
    /// If a display name is not provided, the username will be used as the display name.
    ///
    /// - Parameters:
    ///   - username: The unique identifier for the user.
    ///   - displayName: An optional display name for the user. Defaults to `nil`.
    public init(username: String, displayName: String? = nil) {
        self.id = username
        self.displayName = displayName ?? username
    }

    /// A computed property that creates a `PublicKeyCredentialUserEntity` instance for WebAuthn authentication.
    ///
    /// This property is intended for use in the registration and authentication processes of WebAuthn,
    /// converting a `PasskeyUser` into a format compatible with WebAuthn's requirements.
    public var webAuthnUser: PublicKeyCredentialUserEntity {
        guard let id = id else {
            fatalError("PasskeyUser must have an ID to be used with WebAuthn.")
        }
        return PublicKeyCredentialUserEntity(
            id: [UInt8](id.utf8), name: id, displayName: displayName)
    }
}

/// Conformance to `ModelSessionAuthenticatable` enables the `PasskeyUser` to be used with Vapor's session authentication.
///
/// This allows `PasskeyUser` instances to be authenticated via session cookies, integrating seamlessly with Vapor's authentication system.
extension PasskeyUser: ModelSessionAuthenticatable {}