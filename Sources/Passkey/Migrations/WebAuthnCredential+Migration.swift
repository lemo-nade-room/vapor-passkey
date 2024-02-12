import Fluent

extension WebAuthnCredential {
    /// `Migration` provides the necessary steps to prepare and revert the database schema for `WebAuthnCredential` entities.
    ///
    /// This struct conforms to `AsyncMigration`, enabling Fluent to perform asynchronous operations
    /// to modify the database schema. It defines how to create and remove the `webauth_credentals` table,
    /// including its fields and constraints, to store WebAuthn credentials associated with users.
    public struct Migration: AsyncMigration {

        /// Initializes a new `Migration` instance.
        public init() {}

        /// Prepares the database for storing `WebAuthnCredential` entities.
        ///
        /// This function creates the `webauth_credentals` table with the necessary fields: `id`, `public_key`,
        /// `current_sign_count`, `passkey_user_id`, and `created_at`. It also establishes a foreign key relationship
        /// to the `passkey_users` table and sets the `id` field as unique.
        ///
        /// - Parameter database: The `Database` instance on which the schema modifications will be performed.
        /// - Throws: An error if the schema creation fails.
        public func prepare(on database: Database) async throws {
            try await database.schema("webauth_credentals")
                .field("id", .string, .identifier(auto: false), .required)
                .field("public_key", .string, .required)
                .field("current_sign_count", .int, .required)
                .field(
                    "passkey_user_id", .string, .required,
                    .references("passkey_users", "username", onDelete: .cascade)
                )
                .field("created_at", .datetime, .required)
                .unique(on: "id")
                .create()
        }

        /// Reverts the changes made by the `prepare` method.
        ///
        /// This function deletes the `webauth_credentals` table from the database, effectively undoing the schema creation.
        /// - Parameter database: The `Database` instance from which the schema will be removed.
        /// - Throws: An error if the schema deletion fails.
        public func revert(on database: Database) async throws {
            try await database.schema("webauth_credentals").delete()
        }
    }
}
