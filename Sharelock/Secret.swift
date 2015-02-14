// Secret.swift
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

@objc class Secret: NSObject {

    var data: String?
    var aclString: String?
    var link: NSURL?
    var acl: [String] {
        get {
            if let list = self.aclString {
                return split(
                    list, {$0 == ","},
                    maxSplit: Int.max,
                    allowEmptySlices: false
                    ).map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
            } else {
                return [];
            }
        }
    }

    func hasValidData() -> Bool {
        if let data = self.data {
            return (1...500).contains(countElements(data))
        }
        return false
    }

    func hasValidACL() -> Bool {
        let list = self.acl
        if (countElements(list) == 0) {
            return false
        }
        let email = NSPredicate(format: "SELF MATCHES %@", "^[^\\@]+\\@[^\\.]+\\..+")
        let twitter = NSPredicate(format: "SELF MATCHES %@", "^\\@([^\\.]+)")
        let domain = NSPredicate(format: "SELF MATCHES %@", "^\\@([^\\.]+\\..+)")
        let predicates: Array = [email!, twitter!, domain!]
        let predicate = NSCompoundPredicate.orPredicateWithSubpredicates(predicates)
        let validList = list.filter { return predicate.evaluateWithObject($0) }
        return countElements(validList) == countElements(list)
    }
}
