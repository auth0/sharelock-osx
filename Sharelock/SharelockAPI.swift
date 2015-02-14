// SharelockAPI.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Cocoa

let SharelockAPIDomainError = "com.auth0.sharelock.api"

@objc class SharelockAPI: NSObject {

    let baseURL: NSURL

    init(baseURL: NSURL) {
        self.baseURL = baseURL
    }

    func linkForSecret(secret: Secret, callback: (Secret, NSError?) -> Void) {
        let newURL = NSURL(string: "create", relativeToURL: self.baseURL)!
        let params = ["d": secret.data!, "a": secret.aclString!]
        request(.POST, newURL, parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { (_, response, responseString, err) in
                if let error = err {
                    if (response?.statusCode == 400) {
                        let badRequestError = NSError(domain: SharelockAPIDomainError, code: 0, userInfo: [
                            NSLocalizedDescriptionKey: NSLocalizedString("Couldn't generate link", comment: "Link Generation Failed Title"),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Please check that you provide a valid email or twitter handle", comment: "Link Generation Failed Message")
                            ])
                        callback(secret, badRequestError)
                    } else {
                        callback(secret, error)
                    }
                } else {
                    if let link = NSURL(string: responseString!, relativeToURL: self.baseURL) {
                        secret.link = link
                        callback(secret, nil)
                    } else {
                        let invalidLinkError = NSError(domain: SharelockAPIDomainError, code: 1, userInfo: [
                            NSLocalizedDescriptionKey: NSLocalizedString("Couldn't generate link", comment: "Link Generation Failed Title"),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("The link generated was invalid. Please try again later.", comment: "Invalid Link Message")
                            ])
                        callback(secret, invalidLinkError)
                    }
                }
        }
    }
}
