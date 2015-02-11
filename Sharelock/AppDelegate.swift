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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet var menu: NSMenu!

    var sharelockController: NewSharelockViewController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        sharelockController = NewSharelockViewController(nibName: "NewSharelockViewController", bundle: nil)
        sharelockController.preferredContentSize = NSSize(width: 651, height: 400)
        let image = NSImage(named: "Sharelock-MenuBar")
        image?.setTemplate(true)
        let appearance = CCNStatusItemWindowAppearance.defaultAppearance()
        appearance.backgroundColor = NSColor.blackColor()
        appearance.presentationTransition = CCNPresentationTransition.SlideAndFade
        CCNStatusItem.setWindowAppearance(appearance)
        CCNStatusItem.presentStatusItemWithImage(image, contentViewController: sharelockController)
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        let modifiers: UInt = NSEventModifierFlags.ControlKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue | NSEventModifierFlags.CommandKeyMask.rawValue
        let key: UInt = UInt(kVK_ANSI_V)
        let shortcut = MASShortcut(keyCode: key, modifierFlags: modifiers)
        let action = { () -> Void in
            CCNStatusItem.sharedInstance().statusItem.button?.performClick(nil)
            return;
        }
        MASShortcutMonitor.sharedMonitor().registerShortcut(shortcut, withAction: action)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
}
