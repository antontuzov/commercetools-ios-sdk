//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import Foundation

/**
    All endpoints capable of being updated by key should conform to this protocol.

    Default implementation provides update by key capability for all Commercetools endpoints which do support it.
*/
public protocol UpdateByKeyEndpoint: Endpoint {

    /**
        Updates an object by UUID at the endpoint specified with `path` value.

        - parameter key:                      The key value used to reference resource to be updated.
        - parameter version:                  Version of the object (for optimistic concurrency control).
        - parameter actions:                  An array of actions to be executed, in dictionary representation.
        - parameter expansion:                An optional array of expansion property names.
        - parameter result:                   The code to be executed after processing the response, providing model
                                              instance in case of a successful result.
    */
    static func updateByKey(_ key: String, version: UInt, actions: [[String: Any]], expansion: [String]?, result: @escaping (Result<ResponseType>) -> Void)
}

public extension UpdateByKeyEndpoint {
    
    static func updateByKey(_ key: String, version: UInt, actions: [[String: Any]], expansion: [String]? = nil, result: @escaping (Result<ResponseType>) -> Void) {
        
        requestWithTokenAndPath(result, { token, path in
            let fullPath = pathWithExpansion("\(path)key=\(key)", expansion: expansion)
            let request = self.request(url: fullPath, method: .post, json: ["version": version, "actions": actions], headers: self.headers(token))

            perform(request: request) { (response: Result<ResponseType>) in
                result(response)
            }
        })
    }
}