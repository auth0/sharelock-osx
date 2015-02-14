// SharelockContentViewController.m
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

#import "SharelockContentViewController.h"
#import "HyperlinkTextField.h"
#import "CCNStatusItem.h"
#import "Sharelock-Swift.h"

NSString * const ShowSettingsNotification = @"ShowSettingsNotification";

@interface SharelockContentViewController ()

@property (strong, nonatomic) IBOutlet NSMenu *settingsMenu;
@property (weak, nonatomic) IBOutlet NSTextField *encryptMessage;
@property (weak, nonatomic) IBOutlet NSButton *shareButton;
@property (weak, nonatomic) IBOutlet HyperlinkTextField *linkField;
@property (weak, nonatomic) IBOutlet NSTextField *shareField;
@property (weak, nonatomic) IBOutlet NSTextField *dataField;
@property (weak, nonatomic) IBOutlet NSView *fieldContainerView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation SharelockContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fieldContainerView.wantsLayer = YES;
    self.fieldContainerView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
}

- (void)viewDidAppear {
    self.dataField.stringValue = @"";
    self.shareField.stringValue = @"";
    self.linkField.stringValue = @"";
    self.shareButton.enabled = NO;
    self.shareField.toolTip = NSLocalizedString(@"Email addresses (e.g. john@example.com), Twitter handles (e.g. @johnexample), email domain names (e.g. @example.com)", @"Share Field Tooltip");
    self.dataField.toolTip = NSLocalizedString(@"Passwords, keys, URLs, any text up to 500 characters.", @"Data Field Tooltip");
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(finishedEditing:) name:NSControlTextDidEndEditingNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(textChanged:) name:NSControlTextDidChangeNotification object:nil];
}

- (void)viewDidDisappear {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)showSettings:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSettingsNotification object:nil];
}

- (IBAction)quitSharelock:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)showMenu:(NSButton *)button {
    NSRect frame = button.frame;
    NSPoint menuOrigin = [button.superview convertPoint:NSMakePoint(frame.origin.x, frame.origin.y - 10) fromView:nil];
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:menuOrigin modifierFlags:0 timestamp:0 windowNumber:button.window.windowNumber context:button.window.graphicsContext eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu:self.settingsMenu withEvent:event forView:button];
}

- (IBAction)shareLink:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[self.linkField.stringValue]];
    [[[[CCNStatusItem sharedInstance] statusItem] button] performClick:self];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Ready to share", @"Link in Clipboard Title");
    notification.informativeText = NSLocalizedString(@"Your secured link is in your Clipboard", @"Link in Clipboard Message");
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)textChanged:(NSNotification *)notification {
    self.linkField.stringValue = @"";
    self.shareButton.enabled = NO;
}

- (void)finishedEditing:(NSNotification *)notification {
    if (self.linkField.stringValue.length > 0) {
        return;
    }

    self.shareButton.enabled = NO;
    Secret *secret = [[Secret alloc] init];
    secret.data = self.dataField.stringValue;
    secret.aclString = self.shareField.stringValue;
    BOOL aclValid = [secret hasValidACL];
    BOOL dataValid = [secret hasValidData];
    self.dataField.textColor = dataValid || secret.data.length == 0 ? [NSColor blackColor] : [NSColor redColor];
    self.shareField.textColor = aclValid || secret.acl.count == 0 ? [NSColor blackColor] : [NSColor redColor];

    if (dataValid && aclValid) {
        [self showProgress:YES];
        SharelockAPI *api = [[SharelockAPI alloc] initWithBaseURL:[[NSUserDefaults standardUserDefaults] sharelockURL]];
        [api linkForSecret:secret callback:^(Secret *secret, NSError *error) {
            [self showProgress:NO];
            if (error) {
                NSUserNotification *notification = [[NSUserNotification alloc] init];
                notification.title = error.localizedDescription;
                notification.informativeText = error.localizedFailureReason;
                notification.soundName = NSUserNotificationDefaultSoundName;
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            } else {
                NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:secret.link.absoluteString];
                [linkString beginEditing];
                [linkString addAttribute:NSLinkAttributeName value:secret.link range:NSMakeRange(0, linkString.length)];
                [linkString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:0.290196078 green:0.564705882 blue:0.88627451 alpha:1.0] range:NSMakeRange(0, linkString.length)];
                [linkString endEditing];
                self.linkField.attributedStringValue = linkString;
                self.shareButton.enabled = YES;
                [self.shareButton.window makeFirstResponder:self.shareButton];
            }
        }];
    }
}

- (void)showProgress:(BOOL)inProgress {
    if (inProgress) {
        self.linkField.stringValue = @"";
        [self.progressIndicator startAnimation:self];
        self.linkField.hidden = YES;
        self.encryptMessage.hidden = NO;
    } else {
        [self.progressIndicator stopAnimation:self];
        self.linkField.hidden = NO;
        self.encryptMessage.hidden = YES;
    }
}

@end
