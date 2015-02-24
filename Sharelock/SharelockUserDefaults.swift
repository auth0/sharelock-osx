// SharelockUserDefaults.swift
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

import Foundation

let SharelockGlobalShortcutKey = "SharelockGlobalShortcut"
let SharelockEndpointURLKey = "SharelockEndpointURL"
let SharelockEndpointFirstRunKey = "SharelockEndpointFirstRun"
let SharelockPasteFromClipboardKey = "SharelockPasteFromClipboard"

func SharelockDefaultShortcut() -> MASShortcut {
    let modifiers: UInt = NSEventModifierFlags.ControlKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue | NSEventModifierFlags.CommandKeyMask.rawValue
    let key: UInt = UInt(kVK_ANSI_V)
    return MASShortcut(keyCode: key, modifierFlags: modifiers)
}

let SharelockDefaultURL = NSURL(string:"https://sharelock.io")!

extension NSUserDefaults {

    var firstRun:Bool {
        get {
            return self.boolForKey(SharelockEndpointFirstRunKey)
        }
        set {
            self.setBool(newValue, forKey: SharelockEndpointFirstRunKey)
        }
    }

    var pasteFromClipboard:Bool {
        get {
            return self.boolForKey(SharelockPasteFromClipboardKey)
        }
        set {
            self.setBool(newValue, forKey: SharelockPasteFromClipboardKey)
        }
    }

    func registerSharelockURL(url: NSURL) {
        self.setObject(NSKeyedArchiver.archivedDataWithRootObject(url), forKey: SharelockEndpointURLKey)
    }

    func sharelockURL() -> NSURL? {
        var url: NSURL?
        if let data = self.dataForKey(SharelockEndpointURLKey) {
           url = NSKeyedUnarchiver.unarchiveObjectWithData(data) as NSURL?
        }
        return url
    }

    func registerSharelockDefaults() {
        self.registerDefaults([
            SharelockEndpointURLKey: NSKeyedArchiver.archivedDataWithRootObject(SharelockDefaultURL),
            SharelockEndpointFirstRunKey: true,
            SharelockPasteFromClipboardKey: true
            ])
    }
}