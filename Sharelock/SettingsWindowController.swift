// SettingsWindowController.swift
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

class SettingsWindowController: NSWindowController {

    @IBOutlet weak var sharelockEndpointField: NSTextField!
    @IBOutlet weak var shortcutView: MASShortcutView!
    @IBOutlet weak var sharelockVersion: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()
        let defaults = NSUserDefaults.standardUserDefaults()
        if let url = defaults.sharelockURL() {
            self.sharelockEndpointField.stringValue = url.absoluteString!
        }
        let bundleInfo = NSBundle.mainBundle().infoDictionary!
        let marketingVersion = bundleInfo["CFBundleShortVersionString"] as String
        let buildNumber = bundleInfo["CFBundleVersion"] as String
        self.sharelockVersion.stringValue = "v\(marketingVersion) (\(buildNumber))"
    }
    
    @IBAction func applyChanges(sender: AnyObject) {
        let userShortcut:MASShortcut? = self.shortcutView.shortcutValue
        let sharelockEndpoint = self.sharelockEndpointField.stringValue
        if let endpointURL = NSURL(string: sharelockEndpoint) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.registerSharelockURL(endpointURL)
            defaults.synchronize()
        }
        if let shortcut = userShortcut {
            MASShortcutBinder.sharedBinder().registerDefaultShortcuts([SharelockGlobalShortcutKey: shortcut])
        }
        self.close()
    }

    @IBAction func discardChanges(sender: AnyObject) {
        self.close()
    }

    @IBAction func restoreDefaults(sender: AnyObject) {
        self.sharelockEndpointField.stringValue = SharelockDefaultURL.absoluteString!
        self.shortcutView.shortcutValue = SharelockDefaultShortcut()
    }
}
