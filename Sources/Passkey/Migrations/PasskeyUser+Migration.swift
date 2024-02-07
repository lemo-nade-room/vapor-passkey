import Fluent

extension PasskeyUser {
    /// `Migration` provides the necessary steps to prepare and revert the database schema for `PasskeyUser` entities.
    ///
    /// This struct conforms to `AsyncMigration`, allowing Fluent to execute asynchronous operations
    /// to modify the database schema. It defines how to create and remove the `passkey_users` table,
    /// including its fields and constraints.
    public struct Migration: AsyncMigration {
        /// Prepares the database for storing `PasskeyUser` entities.
        ///
        /// This function creates the `passkey_users` table with the necessary fields: `username`, `display_name`, and `created_at`.
        /// - Parameter database: The `Database` instance on which the schema modifications will be performed.
        /// - Throws: An error if the schema creation fails.
        public func prepare(on database: Database) async throws {
            try await database.schema("passkey_users")
                .field("username", .string, .identifier(auto: false), .required)
                .field("display_name", .string, .required)
                // Creates a `created_at` field to store the datetime when the record was created, and is required.
                .field("created_at", .datetime, .required)
                .create()
        }

        /// Reverts the changes made by the `prepare` method.
        ///
        /// This function deletes the `passkey_users` table from the database, effectively undoing the schema creation.
        /// - Parameter database: The `Database` instance from which the schema will be removed.
        /// - Throws: An error if the schema deletion fails.
        public func revert(on database: Database) async throws {
            try await database.schema("passkey_users").delete()
        }
    }
}
