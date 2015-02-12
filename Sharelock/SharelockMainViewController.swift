// SharelockMainViewController.swift
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

class SharelockMainViewController: NSViewController {

    @IBOutlet var settingsMenu: NSMenu!
    @IBOutlet weak var encryptMessage: NSTextField!
    @IBOutlet weak var shareButton: NSButton!
    @IBOutlet weak var linkField: HyperlinkTextField!
    @IBOutlet weak var shareField: NSTextField!
    @IBOutlet weak var dataField: NSTextField!
    @IBOutlet weak var fieldContainerView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fieldContainerView.wantsLayer = true
        self.fieldContainerView.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }

    override func viewDidAppear() {
        self.dataField.stringValue = ""
        self.shareField.stringValue = ""
        self.linkField.stringValue = ""
        self.shareButton.enabled = false
        self.shareField.toolTip = NSLocalizedString("Email addresses (e.g. john@example.com), Twitter handles (e.g. @johnexample), email domain names (e.g. @example.com)", comment: "Share Field Tooltip")
        self.dataField.toolTip = NSLocalizedString("Passwords, keys, URLs, any text up to 500 characters.", comment:"Data Field Tooltip")
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "finishedEditing:", name: NSControlTextDidEndEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: "textChanged:", name: NSControlTextDidChangeNotification, object: nil)
    }

    override func viewDidDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @IBAction func showSettings(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(ShowSettingsNotification, object: nil)
    }

    @IBAction func quitSharelock(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(nil)
    }

    @IBAction func showMenu(sender: AnyObject) {
        let button = sender as NSButton
        let frame = button.frame
        let menuOrigin = button.superview?.convertPoint(NSMakePoint(frame.origin.x, frame.origin.y - 10), toView: nil)
        let windowNumber = button.window?.windowNumber
        let event = NSEvent.mouseEventWithType(NSEventType.LeftMouseDown, location: menuOrigin!, modifierFlags: NSEventModifierFlags.allZeros, timestamp: 0, windowNumber: windowNumber!, context: button.window?.graphicsContext, eventNumber: 0, clickCount: 1, pressure: 1)
        NSMenu.popUpContextMenu(self.settingsMenu, withEvent: event!, forView: button)
    }

    @IBAction func shareLink(sender: AnyObject) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.writeObjects([self.linkField.stringValue])
        CCNStatusItem.sharedInstance().statusItem.button?.performClick(self)
        let notification = NSUserNotification()
        notification.title = NSLocalizedString("Ready to share", comment: "Link in Clipboard Title")
        notification.informativeText = NSLocalizedString("Your secured link is in your Clipboard", comment: "Link in Clipboard Message")
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }

    func textChanged(notification: NSNotification) {
        self.linkField.stringValue = ""
        self.shareButton.enabled = false
    }

    func finishedEditing(notification: NSNotification) {
        if countElements(self.linkField.stringValue) > 0 {
            return;
        }
        self.shareButton.enabled = false

        let data = self.dataField.stringValue
        let sharelist = self.shareField.stringValue
        let list = split(sharelist, {$0 == ","}, maxSplit: Int.max, allowEmptySlices: false)
                    .map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())}
        let shareListIsValid = self.validateShareList(list)
        let dataIsValid = (1...500).contains(countElements(data))

        self.dataField.textColor = dataIsValid || countElements(data) == 0 ? NSColor.blackColor() : NSColor.redColor()
        self.shareField.textColor = shareListIsValid || countElements(sharelist) == 0 ? NSColor.blackColor() : NSColor.redColor()
        if (dataIsValid && shareListIsValid) {
            println("Generating link...")
            self.showProgress(true)

            let baseURL = NSUserDefaults.standardUserDefaults().sharelockURL()!
            let newURL = NSURL(string: "create", relativeToURL: baseURL)!


            let params = ["d": data, "a": sharelist]
            request(.POST, newURL, parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { [weak self] (_, response, responseString, err) in
                self?.showProgress(false)
                if let error = err {
                    println("Failed to fetch link with error \(error), response \(responseString) and status code \(response?.statusCode)")
                    if (response?.statusCode == 400) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let notification = NSUserNotification()
                            notification.title = NSLocalizedString("Couldn't generate link", comment: "Link Generation Failed Title")
                            notification.informativeText = NSLocalizedString("Please check that you provide a valid email or twitter handle", comment: "Link Generation Failed Message")
                            notification.soundName = NSUserNotificationDefaultSoundName
                            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                        })
                    }
                } else {
                    println("Obtained link \(responseString)")
                    if let link = NSURL(string: responseString!, relativeToURL: baseURL) {
                        let hyperlinkString = NSMutableAttributedString(string:link.absoluteString!)
                        hyperlinkString.beginEditing()
                        hyperlinkString.addAttribute(NSLinkAttributeName, value: link, range: NSMakeRange(0, hyperlinkString.length))
                        let linkColor = NSColor(calibratedRed: 0.290196078, green: 0.564705882, blue: 0.88627451, alpha: 1)
                        hyperlinkString.addAttribute(NSForegroundColorAttributeName, value: linkColor, range: NSMakeRange(0, hyperlinkString.length))
                        hyperlinkString.endEditing()
                        self?.linkField.attributedStringValue = hyperlinkString
                        self?.shareButton.enabled = true
                        self?.linkField.resignFirstResponder()
                        self?.dataField.resignFirstResponder()
                    }
                }
            }
        }
    }

    private func showProgress(inProgress:Bool) {
        if inProgress {
            self.linkField.stringValue = ""
            self.progressIndicator.startAnimation(self)
            self.linkField.hidden = true
            self.encryptMessage.hidden = false
        } else {
            self.progressIndicator.stopAnimation(self)
            self.linkField.hidden = false
            self.encryptMessage.hidden = true
        }
    }

    private func validateShareList(list: [String]) -> Bool {
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
