//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import Foundation
import Alamofire

/**
    Responsible for obtaining, refreshing and persisting OAuth token, both for client credentials and password flows.
*/
public class AuthManager {

    /**
        Enum used to specify current token state.

        - CustomerToken:    Auth manager is handling tokens for a logged in customer.
        - AnonymousToken:   Auth manager is handling tokens for an anonymous customer.
        - PlainToken:       Auth manager is handling a token without an associated customer.
        - NoToken:          Auth manager does not have a token (i.e. because Commercetools configuration is not valid)
    */
    public enum TokenState: Int {
        case CustomerToken   = 0
        case AnonymousToken  = 1
        case PlainToken      = 2
        case NoToken         = 3
    }

    // MARK: - Properties

    /// A shared instance of `AuthManager`, which should be used by other SDK objects.
    public static let sharedInstance = AuthManager()

    /// A property used for setting the `anonymous_id` while obtaining anonymous session access and refresh tokens.
    var anonymousId: String?

    /// The current state auth manager is handling.
    public private(set) var state: TokenState {
        get {
            return tokenStore.tokenState ?? .NoToken
        }
        set {
            tokenStore.tokenState = newValue
        }
    }

    /// The token store used for loading and storing access and refresh tokens.
    let tokenStore = TokenStore()

    /// The auth token which should be included in all requests against Commercetools service.
    private var accessToken: String? {
        get {
            return tokenStore.accessToken
        }
        set {
            tokenStore.accessToken = newValue
        }
    }

    /// The refresh token used to obtain new auth token for password flow.
    private var refreshToken: String? {
        get {
            return tokenStore.refreshToken
        }
        set {
            tokenStore.refreshToken = newValue
        }
    }

    /// The auth token valid before date.
    private var tokenValidDate: NSDate? {
        get {
            return tokenStore.tokenValidDate
        }
        set {
            tokenStore.tokenValidDate = newValue
        }
    }

    /// The URL used for requesting token for client credentials and refresh token flow.
    private var clientCredentialsUrl: String? {
        if let config = Config.currentConfig, baseAuthUrl = config.authUrl where config.validate() {
            return baseAuthUrl + "oauth/token"
        }
        return nil
    }

    /// The URL used for requesting an access and refresh token for an anonymous session
    private var anonymousSessionTokenUrl: String? {
        if let config = Config.currentConfig, baseAuthUrl = config.authUrl, projectKey = config.projectKey
                where config.validate() {
            return "\(baseAuthUrl)oauth/\(projectKey)/anonymous/token"
        }
        return nil
    }

    /// The URL used for requesting token for password flow.
    private var loginUrl: String? {
        if let config = Config.currentConfig, baseAuthUrl = config.authUrl, projectKey = config.projectKey
                where config.validate() {
            return "\(baseAuthUrl)oauth/\(projectKey)/customers/token"

        }
        return nil
    }

    /// Bool property indicating whether the manager should obtain anonymous session token or plain token.
    private var usingAnonymousSession = false

    /// The HTTP headers containing basic HTTP auth needed to obtain the tokens.
    private var authHeaders: [String: String]? {
        if let config = Config.currentConfig, clientId = config.clientId, clientSecret = config.clientSecret,
        authData = "\(clientId):\(clientSecret)".dataUsingEncoding(NSUTF8StringEncoding) where config.validate() {

            var headers = Manager.defaultHTTPHeaders
            headers["Authorization"] = "Basic \(authData.base64EncodedStringWithOptions([]))"
            return headers

        }
        return nil
    }

    /// The serial queue used for processing token requests.
    private let serialQueue = dispatch_queue_create("com.commercetools.authQueue", DISPATCH_QUEUE_SERIAL);

    // MARK: - Lifecycle

    /**
        Private initializer prevents `AuthManager` usage without using `sharedInstance`.
    */
    private init() {}

    // MARK: - Accessing token

    /**
        This method should be used for user login. After successful login the new auth token is used for all
        further requests with Commercetools services.
        In case this method is called before previously logging user out, it will automatically logout (i.e remove
        previously stored tokens).

        - parameter username:           The user's username.
        - parameter password:           The user's password.
        - parameter completionHandler:  The code to be executed once the token fetching completes.
    */
    public func loginUser(username: String, password: String, completionHandler: (NSError?) -> Void) {
        // Process all token requests using private serial queue to avoid issues with race conditions
        // when multiple credentials / login requests can lead auth manager in an unpredictable state
        dispatch_async(serialQueue, {
            let semaphore = dispatch_semaphore_create(0)
            if self.state != .PlainToken {
                self.logoutUser()
            }
            self.processLoginUser(username, password: password, completionHandler: { token, error in
                completionHandler(error)
                dispatch_semaphore_signal(semaphore)
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        })
    }

    /**
        This method will clear all tokens both from memory and persistent storage.
        Most common use case for this method is user logout.
    */
    public func logoutUser() {
        clearAllTokens()

        Log.debug("Getting new anonymous access token after user logout")
        token { _, error in
            if let error = error {
                Log.error("Could not obtain auth token "
                        + (error.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? ""))
            }
        }
    }

    /**
        This method should be used to override `anonymousSession` Bool parameter from the configuration and get new tokens.
        Once this method is invoked, any previously logged in user will be logged out. In case there was an anonymous
        session active, the refresh token will be removed, and the session will not be recoverable any more.
        Most common use case for this method is user logout.

        - parameter usingSession:       Bool parameter indicating whether anonymous session should be used.
        - parameter anonymousId:        Optional argument to assign custom value for `anonymous_id`.
        - parameter completionHandler:  The code to be executed once the token fetching completes.
    */
    public func obtainAnonymousToken(usingSession usingSession: Bool, anonymousId: String? = nil, completionHandler: (NSError?) -> Void) {
        // Process all token requests using private serial queue to avoid issues with race conditions
        // when switching between
        dispatch_async(serialQueue, {
            self.anonymousId = anonymousId
            self.usingAnonymousSession = usingSession
            self.clearAllTokens()
            self.token { _, error in
                completionHandler(error)
            }
        })
    }

    /**
        This method provides auth token to be used in all requests to Commercetools services.
        In case the token has already been obtained, and it's still valid, completion handler
        gets called without network request.
        If the token has expired, the new one will be obtained and passed via completion handler.

        - parameter completionHandler:  The code to be executed once the token fetching completes.
    */
    func token(completionHandler: (String?, NSError?) -> Void) {
        // Process all token requests using private serial queue to avoid issues with race conditions
        // when multiple credentials / login requests can lead auth manager in an unpredictable state
        dispatch_async(serialQueue, {
            let semaphore = dispatch_semaphore_create(0)
            self.processTokenRequest { token, error in
                completionHandler(token, error)
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        })
    }

    /**
        When the current configuration changes, we want to invoke reload tokens on the token store
        for the specific project from the newly specified config. Also, in case the new configuration contains
        different anonymous token preferences, they will be applied after this method call.
    */
    func updatedConfig() {
        tokenStore.reloadTokens()

        if let config = Config.currentConfig where config.validate() {
            usingAnonymousSession = config.anonymousSession ?? false
        }

        if (state == .AnonymousToken && !usingAnonymousSession) ||
                (state == .PlainToken && usingAnonymousSession) {
            logoutUser()
        }
    }

    // MARK: - Retrieving tokens from the auth API

    private func processTokenRequest(completionHandler: (String?, NSError?) -> Void) {
        if let config = Config.currentConfig where config.validate() {
            if let accessToken = accessToken, tokenValidDate = tokenValidDate where tokenValidDate.compare(NSDate()) == .OrderedDescending {
                if refreshToken == nil {
                    self.state = .PlainToken
                }
                completionHandler(accessToken, nil)

            } else {
                accessToken = nil
                tokenValidDate = nil

                if refreshToken != nil {
                    refreshToken(completionHandler)
                } else {
                    obtainAnonymousToken(completionHandler)
                }
            }
        } else {
            let description = "Cannot obtain access token without valid configuration present."
            Log.error(description)
            completionHandler(nil, Error.error(code: .ConfigurationValidationFailed, failureReason: "invalid_configuration", description: description))
        }
    }

    private func processLoginUser(username: String, password: String, completionHandler: (String?, NSError?) -> Void) {
        if let loginUrl = loginUrl, authHeaders = authHeaders, scope = Config.currentConfig?.scope {
            Alamofire.request(.POST, loginUrl, parameters: ["grant_type": "password", "scope": scope, "username": username, "password": password], encoding: .URLEncodedInURL, headers: authHeaders)
            .responseJSON(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionHandler: { response in
                self.state = .CustomerToken
                self.handleAuthResponse(response, completionHandler: completionHandler)
            })
        }
    }

    private func obtainAnonymousToken(completionHandler: (String?, NSError?) -> Void) {
        usingAnonymousSession ? obtainAnonymousSessionToken(completionHandler) : obtainPlainAnonymousToken(completionHandler)
    }

    private func obtainAnonymousSessionToken(completionHandler: (String?, NSError?) -> Void) {
        if let authUrl = anonymousSessionTokenUrl, authHeaders = authHeaders, scope = Config.currentConfig?.scope {
            var parameters = ["grant_type": "client_credentials", "scope": scope]
            if let anonymousId = anonymousId {
                parameters["anonymous_id"] = anonymousId
            }

            Alamofire.request(.POST, authUrl, parameters: parameters, encoding: .URLEncodedInURL, headers: authHeaders)
            .responseJSON(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionHandler: { response in
                self.state = .AnonymousToken
                self.handleAuthResponse(response, completionHandler: completionHandler)
            })
        }
    }

    private func obtainPlainAnonymousToken(completionHandler: (String?, NSError?) -> Void) {
        if let authUrl = clientCredentialsUrl, authHeaders = authHeaders, scope = Config.currentConfig?.scope {
            Alamofire.request(.POST, authUrl, parameters: ["grant_type": "client_credentials", "scope": scope], encoding: .URLEncodedInURL, headers: authHeaders)
            .responseJSON(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionHandler: { response in
                self.state = .PlainToken
                self.handleAuthResponse(response, completionHandler: completionHandler)
            })
        }
    }

    private func refreshToken(completionHandler: (String?, NSError?) -> Void) {
        if let authUrl = clientCredentialsUrl, authHeaders = authHeaders, refreshToken = refreshToken {
            Alamofire.request(.POST, authUrl, parameters: ["grant_type": "refresh_token", "refresh_token": refreshToken], encoding: .URLEncodedInURL, headers: authHeaders)
            .responseJSON(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionHandler: { response in
                self.handleAuthResponse(response, completionHandler: completionHandler)
            })
        }
    }

    private func clearAllTokens() {
        accessToken = nil
        refreshToken = nil
        tokenValidDate = nil
        state = .NoToken
    }

    private func handleAuthResponse(response: Response<AnyObject, NSError>, completionHandler: (String?, NSError?) -> Void) {
        if let responseDict = response.result.value as? [String: AnyObject],
                accessToken = responseDict["access_token"] as? String,
                  expiresIn = responseDict["expires_in"] as? Double where response.result.isSuccess {

            self.anonymousId = nil
            completionHandler(accessToken, nil)
            self.accessToken = accessToken
            // Subtracting 10 minutes from the valid period to compensate for the latency
            self.tokenValidDate = NSDate().dateByAddingTimeInterval(expiresIn - 600)
            self.refreshToken = responseDict["refresh_token"] as? String ?? self.refreshToken

        } else if let responseDict = response.result.value as? [String: AnyObject],
                     failureReason = responseDict["error"] as? String,
                        statusCode = response.response?.statusCode where statusCode > 299 {
            // In case we got an error while using refresh token, we want to clear token storage - there's no way
            // to recover from this
            logoutUser()
            completionHandler(nil, Error.error(code: .AccessTokenRetrievalFailed,
                    failureReason: failureReason, description: responseDict["error_description"] as? String))
        } else {
            // Any other error from NSURLErrorDomain (e.g internet offline) - we won't clear token storage
            state = .NoToken
            completionHandler(nil, response.result.error)
        }
    }

}