//
//  Created by Frank Gregor on 21/12/14.
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

#import <Availability.h>
#import "CCNStatusItem.h"
#import "CCNStatusItemWindowController.h"



@interface NSStatusBarButton (Tools)
@end
@implementation NSStatusBarButton (Tools)
- (void)rightMouseDown:(NSEvent *)theEvent {}
@end



#pragma mark - CCNStatusItemView
#pragma mark -

@interface CCNStatusItem () <NSWindowDelegate>
@property (strong) NSStatusItem *statusItem;

@property (assign) CCNStatusItemPresentationMode presentationMode;
@property (assign, nonatomic) BOOL isStatusItemWindowVisible;

@property (strong, nonatomic) CCNStatusItemWindowController *statusItemWindowController;
@property (strong, nonatomic) CCNStatusItemWindowAppearance *windowAppearance;
@end

@implementation CCNStatusItem

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        self.statusItem = nil;
        self.presentationMode = CCNStatusItemPresentationModeUndefined;
        self.isStatusItemWindowVisible = NO;
        self.statusItemWindowController = nil;
        self.windowAppearance = [CCNStatusItemWindowAppearance defaultAppearance];
        self.appearsDisabled = NO;
    }
    return self;
}

- (void)dealloc {
    _statusItem = nil;
    _statusItemWindowController = nil;
    _windowAppearance = nil;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t _onceToken;
    __strong static CCNStatusItem *_sharedInstance;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

- (void)configureWithImage:(NSImage *)itemImage {
    [itemImage setTemplate:YES];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSStatusBarButton *button = self.statusItem.button;
    button.image = itemImage;
    button.target = self;
    button.action = @selector(handleStatusItemButtonAction:);
}

#pragma mark - Creating and Displaying a StatusBarItem

+ (void)presentStatusItemWithImage:(NSImage *)itemImage
             contentViewController:(NSViewController *)contentViewController {

    CCNStatusItem *sharedItem = [CCNStatusItem sharedInstance];
    [sharedItem configureWithImage:itemImage];

    sharedItem.presentationMode = CCNStatusItemPresentationModeImage;
    sharedItem.statusItemWindowController = [[CCNStatusItemWindowController alloc] initWithConnectedStatusItem:sharedItem
                                                                                         contentViewController:contentViewController
                                                                                                    appearance:sharedItem.windowAppearance];
}

#pragma mark - Button Action Handling

- (void)handleStatusItemButtonAction:(id)sender {
    if (self.isStatusItemWindowVisible) {
        [self dismissStatusItemWindow];
    } else {
        [self showStatusItemWindow];
    }
}

#pragma mark - Custom Accessors

- (BOOL)isStatusItemWindowVisible {
    return (self.statusItemWindowController ? self.statusItemWindowController.windowIsOpen : NO);
}

- (void)setWindowAppearance:(CCNStatusItemWindowAppearance *)appearance {
    _windowAppearance = appearance;
    self.statusItem.button.toolTip = appearance.toolTip;
}

- (void)setAppearsDisabled:(BOOL)appearsDisabled {
    self.statusItem.button.appearsDisabled = appearsDisabled;
}

#pragma mark - Handling the Status Item Window

- (void)showStatusItemWindow {
    [self.statusItemWindowController showStatusItemWindow];
}

- (void)dismissStatusItemWindow {
    [self.statusItemWindowController dismissStatusItemWindow];
}

#pragma mark - Handling StatusItem Layout

+ (void)setWindowAppearance:(CCNStatusItemWindowAppearance *)appearance {
    CCNStatusItem *item = [CCNStatusItem sharedInstance];
    item.windowAppearance = appearance;
}

@end
