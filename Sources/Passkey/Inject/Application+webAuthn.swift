import Vapor
import WebAuthn

extension Application {
    /// A `StorageKey` for accessing `WebAuthnManager` within an `Application`.
    ///
    /// This struct acts as a unique key for storing and retrieving a `WebAuthnManager` instance
    /// from the `Application`'s storage. It ensures type-safe access to the WebAuthn functionality.
    public struct WebAuthnKey: StorageKey {
        /// The type of value associated with the `WebAuthnKey`.
        ///
        /// Specifies that the value expected to be stored and retrieved using this key is a `WebAuthnManager`.
        public typealias Value = WebAuthnManager
    }

    /// Provides access to the `WebAuthnManager` for configuring and using WebAuthn within the application.
    ///
    /// This computed property allows getting and setting a `WebAuthnManager` instance on the `Application`.
    /// It facilitates the integration of WebAuthn authentication mechanisms by providing a centralized
    /// manager that can be accessed throughout the application's lifecycle.
    ///
    /// - Warning: Accessing this property without prior configuration will result in a runtime error.
    /// Ensure that `webAuthn` is properly configured during the application setup.
    public var webAuthn: WebAuthnManager {
        get {
            guard let webAuthn = storage[WebAuthnKey.self] else {
                fatalError("WebAuthn is not configured. Use app.webAuthn = ...")
            }
            return webAuthn
        }
        set {
            storage[WebAuthnKey.self] = newValue
        }
    }
}

extension Request {
    /// Provides access to the `WebAuthnManager` configured in the application, scoped to the current request.
    ///
    /// This computed property allows accessing the `WebAuthnManager` from within the handling of a request.
    /// It leverages the application's configured `WebAuthnManager` to perform operations related to WebAuthn,
    /// such as registering and authenticating users, in a way that is consistent with the application's overall
    /// configuration and state.
    ///
    /// - Returns: The `WebAuthnManager` instance configured in the application.
    public var webAuthn: WebAuthnManager { application.webAuthn }
}
