//
//  Created by Frank Gregor on 26.12.14.
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


#import "CCNStatusItemWindow.h"
#import "CCNStatusItemWindowBackgroundView.h"
#import "CCNStatusItem.h"
#import "CCNStatusItemWindowAppearance.h"

@interface CCNStatusItemWindow () {
    CCNStatusItemWindowAppearance *_appearance;
}
@property (strong) NSView *userContentView;
@property (strong, nonatomic) CCNStatusItemWindowBackgroundView *backgroundView;
@end

@implementation CCNStatusItemWindow

+ (instancetype)statusItemWindowWithAppearance:(CCNStatusItemWindowAppearance *)appearance {
    return [[[self class] alloc] initWithContentRect:NSZeroRect styleMask:NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:YES appearance:appearance];
}

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag appearance:(CCNStatusItemWindowAppearance *)appearance {
    _appearance = appearance;
    self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:flag];
    if (self) {
        self.alphaValue = 0.0;
        self.opaque = NO;
        self.hasShadow = YES;
        self.level = NSPopUpMenuWindowLevel;
        self.backgroundColor = [NSColor clearColor];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }

- (void)setContentView:(id)contentView {
    if ([self.userContentView isEqual:contentView]) return;

    NSView *userContentView = (NSView *)contentView;
    NSRect bounds = userContentView.bounds;
    CAEdgeAntialiasingMask antialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;

    self.backgroundView = super.contentView;
    if (!self.backgroundView) {
        self.backgroundView = [[CCNStatusItemWindowBackgroundView alloc] initWithFrame:bounds appearance:_appearance];
        self.backgroundView.wantsLayer = YES;
        self.backgroundView.layer.frame = self.backgroundView.frame;
        self.backgroundView.layer.cornerRadius = _appearance.cornerRadius;
        self.backgroundView.layer.masksToBounds = YES;
        self.backgroundView.layer.edgeAntialiasingMask = antialiasingMask;
        super.contentView = self.backgroundView;
    }

    if (self.userContentView) {
        [self.userContentView removeFromSuperview];
    }

    self.userContentView = userContentView;
    self.userContentView.frame = [self contentRectForFrameRect:bounds];
    self.userContentView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    self.userContentView.wantsLayer = YES;
    self.userContentView.layer.frame = self.userContentView.frame;
    self.userContentView.layer.cornerRadius = _appearance.cornerRadius;
    self.userContentView.layer.masksToBounds = YES;
    self.userContentView.layer.edgeAntialiasingMask = antialiasingMask;

    [self.backgroundView addSubview:self.userContentView];
}

- (id)contentView {
    return self.userContentView;
}

- (NSRect)frameRectForContentRect:(NSRect)contentRect {
    return NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), NSWidth(contentRect), NSHeight(contentRect) + CCNDefaultArrowHeight);
}

@end
