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

let SharelockMainScreenSize = NSSize(width: 410, height: 306)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet var menu: NSMenu!

    var sharelockController: NSViewController!
    var settingsController: NSWindowController!
    var statusItemPopup: AXStatusItemPopup!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.registerAppDefaults()

        sharelockController = SharelockContentViewController(nibName: "SharelockContentViewController", bundle: nil)
        sharelockController.preferredContentSize = SharelockMainScreenSize
        let image = NSImage(named: "icon_sharelock_menu_bar")
        image?.setTemplate(true)
        self.statusItemPopup = AXStatusItemPopup(viewController: sharelockController, image: image)

        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showSettings"), name: ShowSettingsNotification, object: nil)

        let action = { [weak self] () -> Void in
            if let item = self?.statusItemPopup {
                if item.active {
                    item.hidePopover()
                } else {
                    item.showPopoverAnimated(true)
                }
            }
            return;
        }
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(SharelockGlobalShortcutKey, toAction: action)

        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.firstRun) {
            defaults.firstRun = false
            defaults.synchronize()
            let helper = LaunchAtLoginController()
            helper.launchAtLogin = true
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

    func showSettings() {
        self.settingsController = SettingsWindowController(windowNibName: "SettingsWindowController")
        self.settingsController.window?.center()
        self.settingsController.showWindow(self)
        NSApp.activateIgnoringOtherApps(true)
        self.statusItemPopup.hidePopover()
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
