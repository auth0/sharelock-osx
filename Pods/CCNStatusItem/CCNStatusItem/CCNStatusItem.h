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

#import <Cocoa/Cocoa.h>
#import "CCNStatusItemWindowAppearance.h"


typedef NS_ENUM(NSUInteger, CCNStatusItemPresentationMode) {
    CCNStatusItemPresentationModeUndefined = 0,
    CCNStatusItemPresentationModeImage,
    CCNStatusItemPresentationModeCustomView
};


#pragma mark - CCNStatusItem

@interface CCNStatusItem : NSObject

#pragma mark - Creating and Displaying a StatusBarItem

+ (void)presentStatusItemWithImage:(NSImage *)itemImage
             contentViewController:(NSViewController *)contentViewController;

+ (instancetype)sharedInstance;
@property (strong, readonly) NSStatusItem *statusItem;

#pragma mark - Handling the StatusBarItem Image

@property (readonly, nonatomic) BOOL isStatusItemWindowVisible;
@property (readonly, nonatomic) CCNStatusItemPresentationMode presentationMode;
@property (assign, nonatomic) BOOL appearsDisabled;

#pragma mark - Handling the Status Item Window

- (void)showStatusItemWindow;
- (void)dismissStatusItemWindow;


#pragma mark - Handling StatusItem Layout

@property (readonly, nonatomic) CCNStatusItemWindowAppearance *windowAppearance;
+ (void)setWindowAppearance:(CCNStatusItemWindowAppearance *)appearance;

@end



// Each notification has the statusItemWindow as notification object. The userInfo dictionary is nil.
FOUNDATION_EXPORT NSString *const CCNStatusItemWindowWillShowNotification;
FOUNDATION_EXPORT NSString *const CCNStatusItemWindowDidShowNotification;
FOUNDATION_EXPORT NSString *const CCNStatusItemWindowWillDismissNotification;
FOUNDATION_EXPORT NSString *const CCNStatusItemWindowDidDismissNotification;
