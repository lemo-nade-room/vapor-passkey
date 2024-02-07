import Fluent
import Foundation
import Vapor
import WebAuthn

/// A controller for managing Passkey authentication using WebAuthn.
///
/// This controller provides routes for creating, authenticating, and deleting WebAuthn credentials
/// associated with a `PasskeyUser`. It leverages the WebAuthn protocol for secure, passwordless authentication.
public struct PasskeyController: RouteCollection {

    /// The session key for storing the registration challenge.
    public var sessionRegistrationChallengeKey: String
    /// The session key for storing the authentication challenge.
    public var sessionAuthChallengeKey: String

    /// Initializes a new `PasskeyController` with optional custom session keys.
    ///
    /// - Parameters:
    ///   - sessionRegistrationChallengeKey: The session key for the registration challenge. Defaults to `"registrationChallenge"`.
    ///   - sessionAuthChallengeKey: The session key for the authentication challenge. Defaults to `"authChallenge"`.
    public init(
        sessionRegistrationChallengeKey: String = "registrationChallenge",
        sessionAuthChallengeKey: String = "authChallenge"
    ) {
        self.sessionRegistrationChallengeKey = sessionRegistrationChallengeKey
        self.sessionAuthChallengeKey = sessionAuthChallengeKey
    }

    /// Configures the routes for the `PasskeyController`.
    ///
    /// This method sets up the routes for making credentials, authenticating, and deleting credentials.
    ///
    /// - Parameter routes: The `RoutesBuilder` to which the controller's routes will be added.
    public func boot(routes: RoutesBuilder) {
        let makeCredential = routes.grouped("makeCredential")
        makeCredential.get(use: getMakeCredential)
        makeCredential.post(use: createMakeCredential)
        makeCredential.delete(use: deleteMakeCredential)

        let authenticate = routes.grouped("authenticate")
        authenticate.get(use: getAuthenticate)
        authenticate.post(use: postAuthenticate)
    }

    /// Starts the registration process by generating a new challenge for the user.
    ///
    /// - Parameter req: The `Request` object.
    /// - Returns: A `PublicKeyCredentialCreationOptions` object containing the challenge and other parameters for registration.
    /// - Throws: An error if the user is not authenticated.
    public func getMakeCredential(req: Request) async throws -> PublicKeyCredentialCreationOptions {
        let user = try req.auth.require(PasskeyUser.self)
        let options = req.webAuthn.beginRegistration(user: user.webAuthnUser)
        req.session.data[sessionRegistrationChallengeKey] = Data(options.challenge)
            .base64EncodedString()
        return options
    }

    /// Finishes the registration process by validating the user's response to the challenge.
    ///
    /// - Parameter req: The `Request` object.
    /// - Returns: An `HTTPStatus` indicating the outcome of the registration attempt.
    /// - Throws: An error if the user is not authenticated or the registration challenge is missing.
    public func createMakeCredential(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(PasskeyUser.self)
        guard let challengeEncoded = req.session.data[sessionRegistrationChallengeKey],
            let challenge = Data(base64Encoded: challengeEncoded)
        else {
            throw Abort(.badRequest, reason: "Missing registration session ID")
        }
        req.session.data[sessionRegistrationChallengeKey] = nil

        let credential = try await req.webAuthn.finishRegistration(
            challenge: [UInt8](challenge),
            credentialCreationData: req.content.decode(RegistrationCredential.self),
            confirmCredentialIDNotRegisteredYet: { credentialID in
                let existingCredential = try await WebAuthnCredential.query(on: req.db)
                    .filter(\.$id == credentialID)
                    .first()
                return existingCredential == nil
            }
        )

        try await WebAuthnCredential(from: credential, username: user.requireID()).save(on: req.db)

        return .ok
    }

    /// Deletes a user's credential.
    ///
    /// - Parameter req: The `Request` object.
    /// - Returns: An `HTTPStatus` indicating the outcome of the deletion.
    ///  - Throws: An error if the user is not authenticated.
    public func deleteMakeCredential(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(PasskeyUser.self)
        try await user.delete(on: req.db)
        return .noContent
    }

    /// Starts the authentication process by generating a new challenge for the user.
    ///
    /// - Parameter req: The `Request` object.
    /// - Returns: A `PublicKeyCredentialRequestOptions` object containing the challenge and other parameters for authentication.
    /// - Throws: An error if the user is not authenticated.
    public func getAuthenticate(req: Request) async throws -> PublicKeyCredentialRequestOptions {
        let options = try req.webAuthn.beginAuthentication()
        req.session.data[sessionAuthChallengeKey] = Data(options.challenge).base64EncodedString()
        return options
    }

    /// Finishes the authentication process by validating the user's response to the challenge.
    ///
    /// - Parameter req: The `Request` object.
    /// - Returns: An `HTTPStatus` indicating the outcome of the authentication attempt.
    /// - Throws: An error if the user is not authenticated or the authentication challenge is missing.
    public func postAuthenticate(req: Request) async throws -> HTTPStatus {
        guard let challengeEncoded = req.session.data[sessionAuthChallengeKey],
            let challenge = Data(base64Encoded: challengeEncoded)
        else {
            throw Abort(.badRequest, reason: "Missing auth session ID")
        }
        req.session.data[sessionAuthChallengeKey] = nil
        let authenticationCredential = try req.content.decode(AuthenticationCredential.self)
        guard
            let credential = try await WebAuthnCredential.query(on: req.db)
                .filter(\.$id == authenticationCredential.id.urlDecoded.asString())
                .with(\.$user)
                .first()
        else {
            throw Abort(.unauthorized)
        }
        guard let credentialPublicKey = URLEncodedBase64(credential.publicKey).urlDecoded.decoded
        else {
            throw Abort(
                .internalServerError,
                reason: "Invalid credential public key \(credential.publicKey)")
        }

        let verifiedAuthentication = try req.webAuthn.finishAuthentication(
            credential: authenticationCredential,
            expectedChallenge: [UInt8](challenge),
            credentialPublicKey: [UInt8](credentialPublicKey),
            credentialCurrentSignCount: credential.currentSignCount
        )
        credential.currentSignCount = verifiedAuthentication.newSignCount
        try await credential.save(on: req.db)

        req.auth.login(credential.user)
        return .ok
    }
}

extension PublicKeyCredentialCreationOptions: AsyncResponseEncodable {
    /// Encodes the receiver into an HTTP response asynchronously.
    ///
    /// This method allows `PublicKeyCredentialCreationOptions` to be directly returned from a route handler,
    /// automatically encoding it as a JSON response. It sets the response's content type to `application/json`
    /// and encodes the `PublicKeyCredentialCreationOptions` using `JSONEncoder`.
    ///
    /// - Parameter request: The `Request` object that is processing the response.
    /// - Returns: A `Response` object containing the encoded `PublicKeyCredentialCreationOptions`.
    /// - Throws: An error if the encoding fails.
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.contentType = .json
        return try Response(
            status: .ok, headers: headers, body: .init(data: JSONEncoder().encode(self)))
    }
}

extension PublicKeyCredentialRequestOptions: AsyncResponseEncodable {
    /// Encodes the receiver into an HTTP response asynchronously.
    ///
    /// Similar to `PublicKeyCredentialCreationOptions`, this method enables `PublicKeyCredentialRequestOptions`
    /// to be returned from a route handler, encoding it as a JSON response. It ensures the response has the
    /// `application/json` content type and uses `JSONEncoder` for encoding.
    ///
    /// - Parameter request: The `Request` object that is processing the response.
    /// - Returns: A `Response` object containing the encoded `PublicKeyCredentialRequestOptions`.
    /// - Throws: An error if the encoding fails.
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.contentType = .json
        return try Response(
            status: .ok, headers: headers, body: .init(data: JSONEncoder().encode(self)))
    }
}
