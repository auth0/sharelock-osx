//
//  Created by Frank Gregor on 23.12.14.
//  Copyright (c) 2014 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2014 Frank Gregor, <phranck@cocoanaut.com>
 http://cocoanaut.mit-license.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#import <QuartzCore/QuartzCore.h>
#import "CCNStatusItemWindowController.h"
#import "CCNStatusItemWindowAppearance.h"


static const CGFloat CCNTransitionDistance = 8.0;
typedef NS_ENUM(NSUInteger, CCNFadeDirection) {
    CCNFadeDirectionFadeIn = 0,
    CCNFadeDirectionFadeOut
};


@interface CCNStatusItemWindowController () {
    CCNStatusItemWindow *_window;
}
@property (strong) CCNStatusItem *statusItemView;
@property (strong) CCNStatusItemWindowAppearance *windowAppearance;
@property (strong) CCNStatusItemWindow *window;
@end

@implementation CCNStatusItemWindowController

- (id)initWithConnectedStatusItem:(CCNStatusItem *)statusItem
            contentViewController:(NSViewController *)contentViewController
                       appearance:(CCNStatusItemWindowAppearance *)appearance {

    NSAssert(contentViewController.preferredContentSize.width != 0 && contentViewController.preferredContentSize.height != 0, @"[%@] The preferredContentSize of the contentViewController must not be NSZeroSize!", [self className]);

    self = [super init];
    if (self) {
        [self setupDefaults];

        self.statusItemView = statusItem;
        self.windowAppearance = appearance;

        // StatusItem Window
        self.window = [CCNStatusItemWindow statusItemWindowWithAppearance:appearance];
        self.window.contentViewController = contentViewController;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidResignKeyNotification:) name:NSWindowDidResignKeyNotification object:nil];
    }
    return self;
}

- (void)setupDefaults {
    _windowIsOpen = NO;
}

#pragma mark - Helper

- (void)updateWindowFrame {
    CGRect statusItemRect = NSZeroRect;
    statusItemRect = [[self.statusItemView.statusItem.button window] frame];
    CGRect windowFrame = NSMakeRect(NSMinX(statusItemRect) - NSWidth(self.window.frame)/2 + NSWidth(statusItemRect)/2,
                                    NSMinY(statusItemRect) - NSHeight(self.window.frame) - self.windowAppearance.windowToStatusItemMargin,
                                    self.window.frame.size.width,
                                    self.window.frame.size.height);
    [self.window setFrame:windowFrame display:YES];

}

#pragma mark - Handling Window Visibility

- (void)showStatusItemWindow {
    if (self.animationIsRunning) return;

    [self updateWindowFrame];
    [self showWindow:nil];

    [self animateWindow:self.window withFadeDirection:CCNFadeDirectionFadeIn];
}

- (void)dismissStatusItemWindow {
    if (self.animationIsRunning) return;

    [self animateWindow:self.window withFadeDirection:CCNFadeDirectionFadeOut];
}

- (void)animateWindow:(CCNStatusItemWindow *)window withFadeDirection:(CCNFadeDirection)fadeDirection {
    switch (self.windowAppearance.presentationTransition) {
        case CCNPresentationTransitionNone:
        case CCNPresentationTransitionFade: {
            [self animateWindow:window withFadeTransitionUsingFadeDirection:fadeDirection];
            break;
        }
        case CCNPresentationTransitionSlideAndFade: {
            [self animateWindow:window withSlideAndFadeTransitionUsingFadeDirection:fadeDirection];
            break;
        }
    }
}

- (void)animateWindow:(CCNStatusItemWindow *)window withFadeTransitionUsingFadeDirection:(CCNFadeDirection)fadeDirection {
    __weak typeof(self) wSelf = self;
    self.animationIsRunning = YES;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = self.windowAppearance.animationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [[window animator] setAlphaValue:(fadeDirection == CCNFadeDirectionFadeIn ? 1.0 : 0.0)];

    } completionHandler:^{
        wSelf.animationIsRunning = NO;
        wSelf.windowIsOpen = (fadeDirection == CCNFadeDirectionFadeIn);

        if (fadeDirection == CCNFadeDirectionFadeIn) {
            [window makeKeyAndOrderFront:nil];
        }
        else {
            [window orderOut:wSelf];
            [window close];
        }
    }];
}

- (void)animateWindow:(CCNStatusItemWindow *)window withSlideAndFadeTransitionUsingFadeDirection:(CCNFadeDirection)fadeDirection {
    __weak typeof(self) wSelf = self;
    self.animationIsRunning = YES;

    CGRect windowStartFrame, windowEndFrame;
    switch (fadeDirection) {
        case CCNFadeDirectionFadeIn: {
            windowStartFrame = NSMakeRect(NSMinX(window.frame), NSMinY(window.frame) + CCNTransitionDistance, NSWidth(window.frame), NSHeight(window.frame));
            windowEndFrame = window.frame;
            break;
        }
        case CCNFadeDirectionFadeOut: {
            windowStartFrame = window.frame;
            windowEndFrame = NSMakeRect(NSMinX(window.frame), NSMinY(window.frame) + CCNTransitionDistance, NSWidth(window.frame), NSHeight(window.frame));
            break;
        }
    }

    [window setFrame:windowStartFrame display:NO];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = self.windowAppearance.animationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [[window animator] setFrame:windowEndFrame display:NO];
        [[window animator] setAlphaValue:(fadeDirection == CCNFadeDirectionFadeIn ? 1.0 : 0.0)];

    } completionHandler:^{
        wSelf.animationIsRunning = NO;
        wSelf.windowIsOpen = (fadeDirection == CCNFadeDirectionFadeIn);

        if (fadeDirection == CCNFadeDirectionFadeIn) {
            [window makeKeyAndOrderFront:nil];
        }
        else {
            [window orderOut:wSelf];
            [window close];
        }
    }];
}

#pragma mark - Notifications

- (void)handleWindowDidResignKeyNotification:(NSNotification *)note {
    [self dismissStatusItemWindow];
}

@end

