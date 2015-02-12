// AppDelegate.swift
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

let ShowSettingsNotification = "SharelockShowSettings"
let SharelockMainScreenSize = NSSize(width: 374, height: 400)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet var menu: NSMenu!

    var sharelockController: SharelockMainViewController!
    var settingsController: SettingsWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.registerAppDefaults()

        sharelockController = SharelockMainViewController(nibName: "SharelockMainViewController", bundle: nil)
        sharelockController.preferredContentSize = SharelockMainScreenSize
        let image = NSImage(named: "Sharelock-MenuBar")
        image?.setTemplate(true)
        let appearance = CCNStatusItemWindowAppearance.defaultAppearance()
        appearance.backgroundColor = NSColor(calibratedRed: 0.921568627, green: 0.329411765, blue: 0.141176471, alpha: 1)
        appearance.presentationTransition = CCNPresentationTransition.SlideAndFade
        CCNStatusItem.setWindowAppearance(appearance)
        CCNStatusItem.presentStatusItemWithImage(image, contentViewController: sharelockController)

        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showSettings"), name: ShowSettingsNotification, object: nil)

        let action = { () -> Void in
            CCNStatusItem.sharedInstance().statusItem.button?.performClick(nil)
            return;
        }
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(SharelockGlobalShortcutKey, toAction: action)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

    func showSettings() {
        self.settingsController = SettingsWindowController(windowNibName: "SettingsWindowController")
        self.settingsController.showWindow(self)
        NSApp.activateIgnoringOtherApps(true)
    }

    private func registerAppDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerSharelockDefaults()
        defaults.synchronize()

        let shortcut = SharelockDefaultShortcut()
        let binder = MASShortcutBinder.sharedBinder()
        binder.registerDefaultShortcuts([SharelockGlobalShortcutKey: shortcut])
    }
}
