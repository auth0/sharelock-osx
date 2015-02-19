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
#import "CCNStatusItem.h"
#import "Sharelock-Swift.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

NSString * const ShowSettingsNotification = @"ShowSettingsNotification";

@interface SharelockAPI (Reactive)
- (RACSignal *)linkForSecret:(Secret *)secret;
@end

@implementation SharelockAPI (Reactive)

- (RACSignal *)linkForSecret:(Secret *)secret {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self linkForSecret:secret callback:^(Secret *secret, NSError *error) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendNext:secret];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] delay:2];
}

@end

@interface SharelockContentViewController ()

@property (strong, nonatomic) IBOutlet NSMenu *settingsMenu;
@property (weak, nonatomic) IBOutlet NSTextField *dataCharCountLabel;
@property (weak, nonatomic) IBOutlet NSTextField *encryptMessage;
@property (weak, nonatomic) IBOutlet NSButton *shareButton;
@property (weak, nonatomic) IBOutlet NSTextField *shareField;
@property (weak, nonatomic) IBOutlet NSTextField *dataField;
@property (weak, nonatomic) IBOutlet NSView *fieldContainerView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak, nonatomic) IBOutlet NSView *errorMessageContainer;
@property (weak, nonatomic) IBOutlet NSTextField *errorMessageLabel;

@property (strong, nonatomic) RACCommand *command;
@property (strong, nonatomic) Secret *secret;

@end

@implementation SharelockContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.secret = [[Secret alloc] init];
    self.fieldContainerView.wantsLayer = YES;
    self.fieldContainerView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    self.shareField.toolTip = NSLocalizedString(@"Email addresses (e.g. john@example.com), Twitter handles (e.g. @johnexample), email domain names (e.g. @example.com)", @"Share Field Tooltip");
    self.dataField.toolTip = NSLocalizedString(@"Passwords, keys, URLs, any text up to 500 characters.", @"Data Field Tooltip");

    @weakify(self);
    RAC(self.secret, data) = self.dataField.rac_textSignal;
    RAC(self.secret, aclString) = self.shareField.rac_textSignal;
    RACSignal *validData = [RACObserve(self.secret, data) map:^id(id value) {
        return @([Secret hasValidData:value]);
    }];
    RACSignal *validACL = [RACObserve(self.secret, aclString) map:^id(id value) {
        NSArray *acl = [Secret asACL:value];
        return @([Secret hasValidACL:acl]);
    }];
    RACSignal *validSecret = [[RACSignal combineLatest:@[validData, validACL]] and];

    self.command = [[RACCommand alloc] initWithEnabled:validSecret
                                           signalBlock:^RACSignal *(Secret *secret) {
                                               SharelockAPI *api = [[SharelockAPI alloc] initWithBaseURL:[[NSUserDefaults standardUserDefaults] sharelockURL]];
                                               return [api linkForSecret:secret];
                                           }];
    self.command.allowsConcurrentExecution = NO;
    [self.command.errors subscribeNext:^(NSError *error) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = error.localizedDescription;
        notification.informativeText = error.localizedFailureReason;
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }];
    [[self.command.executionSignals flatten] subscribeNext:^(Secret *secret) {
        @strongify(self);
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[secret.link.absoluteString]];
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"Ready to share", @"Link in Clipboard Title");
        notification.informativeText = NSLocalizedString(@"Your secured link is in your Clipboard", @"Link in Clipboard Message");
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        [self closeWindow:nil];
    }];
    RACSignal *throttledValidData = [[validData skip:1] throttle:.5f valuesPassingTest:^BOOL(id next) {
        return ![next boolValue];
    }];
    RACSignal *throttledValidACL = [[validACL skip:1] throttle:.5f valuesPassingTest:^BOOL(NSNumber *value) {
        return ![value boolValue];
    }];

    RAC(self.dataField, textColor) = [throttledValidData map:^id(id value) {
        return [value boolValue] ? [NSColor blackColor] : [NSColor redColor];
    }];
    RAC(self.shareField, textColor) = [throttledValidACL map:^id(id value) {
        return [value boolValue] ? [NSColor blackColor] : [NSColor redColor];
    }];

    RAC(self.shareButton, enabled) = [[RACSignal combineLatest:@[validSecret, [self.command.executing not]]] and];
    RAC(self.encryptMessage, hidden) = [self.command.executing not];
    [self.command.executing subscribeNext:^(id executing) {
        @strongify(self);
        if ([executing boolValue]) {
            [self.progressIndicator startAnimation:self];
        } else {
            [self.progressIndicator stopAnimation:self];
        }
    }];
    RACSignal *dataCharCount = [RACObserve(self.secret, data) map:^id(NSString *value) {
        return @(500 - (NSInteger)value.length);
    }];
    RAC(self.dataCharCountLabel, stringValue) = dataCharCount;
    RAC(self.dataCharCountLabel, textColor) = [[[dataCharCount skip:1] throttle:.5f valuesPassingTest:^BOOL(NSNumber *value) {
        return [value integerValue] < 0;
    }] map:^id(NSNumber *value) {
        return value.integerValue >= 0 ? [NSColor colorWithCalibratedWhite:0.600 alpha:1.000] : [NSColor redColor];
    }];
    RACSignal *throttledValidSecret = [RACSignal combineLatest:@[throttledValidData, throttledValidACL]];
    RAC(self.errorMessageContainer, hidden) = [throttledValidSecret and];
    RAC(self.errorMessageLabel, stringValue) = [throttledValidSecret reduceEach:^id(id validData, id validACL){
        if (![validACL boolValue] && ![validData boolValue]) {
            return NSLocalizedString(@"Please enter a text to share and a list of E-Mail, twitter handle or E-Mail domain names", @"Invalid data & share list message");
        }
        if (![validData boolValue]) {
            return NSLocalizedString(@"Please enter a text to share up to 500 characters", @"Invalid data message");
        }
        if (![validACL boolValue]) {
            return NSLocalizedString(@"Please enter a valid list of E-Mail, twitter handle or E-Mail domain names", @"Invalid share list message");
        }

        return @"";
    }];
}

- (void)viewWillAppear {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *content = [pasteboard stringForType:NSPasteboardTypeString];
    if (content) {
        self.dataField.stringValue = content;
        self.secret.data = content;
        [self.shareField becomeFirstResponder];
        [pasteboard clearContents];
    } else {
        [self.dataField becomeFirstResponder];
    }
}

- (IBAction)showSettings:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSettingsNotification object:nil];
}

- (IBAction)quitSharelock:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)showMenu:(NSButton *)button {
    NSRect frame = button.frame;
    NSPoint menuOrigin = [button.superview convertPoint:NSMakePoint(frame.origin.x, frame.origin.y - 10) toView:nil];
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:menuOrigin modifierFlags:0 timestamp:0 windowNumber:button.window.windowNumber context:button.window.graphicsContext eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu:self.settingsMenu withEvent:event forView:button];
}

- (IBAction)shareLink:(id)sender {
    [self.command execute:self.secret];
}

- (IBAction)goToAuth0Site:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://auth0.com"]];
}

- (IBAction)closeWindow:(id)sender {
    [[[[CCNStatusItem sharedInstance] statusItem] button] performClick:self];
}

@end

