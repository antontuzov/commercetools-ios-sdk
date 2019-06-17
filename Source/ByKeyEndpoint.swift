//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import Foundation

/**
    All endpoints capable of being retrieved by key should conform to this protocol.

    Default implementation provides retrieval by key capability for all Commercetools endpoints which do support it.
*/
public protocol ByKeyEndpoint: Endpoint {

    /**
        Retrieves an object by UUID at the endpoint specified with `path` value.

        - parameter key:                      The key value used retrieve resource.
        - parameter expansion:                An optional array of expansion property names.
        - parameter result:                   The code to be executed after processing the response, providing model
                                              instance in case of a successful result.
    */
    static func byKey(_ key: String, expansion: [String]?, result: @escaping (Result<ResponseType>) -> Void)
}

public extension ByKeyEndpoint {
    
    static func byKey(_ key: String, expansion: [String]? = nil, result: @escaping (Result<ResponseType>) -> Void) {

        requestWithTokenAndPath(result: result) { token, path in
            let fullPath = pathWithExpansion("\(path)key=\(key)", expansion: expansion)
            let request = self.request(url: fullPath, headers: self.headers(token))

            perform(request: request) { (response: Result<ResponseType>) in
                result(response)
            }
        }
    }
}
