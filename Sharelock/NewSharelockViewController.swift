// NewSharelockViewController.swift
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

class NewSharelockViewController: NSViewController {

    @IBOutlet weak var encryptMessage: NSTextField!
    @IBOutlet weak var shareButton: NSButton!
    @IBOutlet weak var linkField: NSTextField!
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
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "finishedEditing:", name: NSControlTextDidEndEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: "textChanged:", name: NSControlTextDidChangeNotification, object: nil)
    }

    @IBAction func shareLink(sender: AnyObject) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.writeObjects([self.linkField.stringValue])
        CCNStatusItem.sharedInstance().statusItem.button?.performClick(self)
        let notification = NSUserNotification()
        notification.title = "Ready to share"
        notification.informativeText = "The link to your data is in your clipboard"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }

    override func viewDidDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
            let params = ["d": data, "a": sharelist]
            request(.POST, "https://sharelock.io/create", parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { [weak self] (_, response, responseString, err) in
                self?.showProgress(false)
                if let error = err {
                    println("Failed to fetch link with error \(error), response \(responseString) and status code \(response?.statusCode)")
                    if (response?.statusCode == 400) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let notification = NSUserNotification()
                            notification.title = "Couldn't generate link"
                            notification.informativeText = "Please check that you provide a valid email or twitter handle"
                            notification.soundName = NSUserNotificationDefaultSoundName
                            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                        })
                    }
                } else {
                    println("Obtained link \(responseString)")
                    self?.linkField.stringValue = "https://sharelock.io\(responseString!)"
                    self?.shareButton.enabled = true
                    self?.linkField.resignFirstResponder()
                    self?.dataField.resignFirstResponder()
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
