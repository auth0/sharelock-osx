[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=phranck&url=https://github.com/phranck/CCNStatusItem&title=CCNStatusItem&tags=github&category=software)
![Travis Status](https://travis-ci.org/phranck/CCNStatusItem.png?branch=master)



## Overview

`CCNStatusItem` is a subclass of `NSObject` to act as a custom view for `NSStatusItem`. Running on Yosemite it has full support for the class `NSStatusBarButton` which is provided by `NSStatusItem` via the `button` property. Yosemite's dark menu mode will be automatically handled.<br />
It supports a customizable statusItemWindow that will manage any `NSViewController` instance for presenting the content.

Here is a shot of the included example application:

![CCNStatusItem Example Application](https://dl.dropbox.com/u/34133216/WebImages/Github/CCNStatusItem.png)


## Integration

You can add `CCNStatusItem` by using CocoaPods. Just add this line to your Podfile:

```
pod 'CCNStatusItem'
```


## Usage

After it's integrated into your project you are just a four-liner away from your (maybe) first `NSStatusItem` with a custom view and a beautiful looking popover window. A good place to add these lines of code is your AppDelegate:

```Objective-C
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
   ...
   [CCNStatusItem presentStatusItemWithImage:[NSImage imageNamed:@"statusbar-icon"]
                       contentViewController:[[ContentViewController alloc] initWithNibName:NSStringFromClass([ContentViewController class]) bundle:nil]];
   ...
}
```

That's all! You will have some options to change the design of this statusItem popover window using `CCNStatusItemWindowDesign`. In the example above internally `CCNStatusItem` uses `[CCNStatusItemWindowDesign defaultDesign]` to set a default design. The next example will show you how to change the design of your statusItem popover window:

```Objective-C
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ...
    
    CCNStatusItemWindowAppearance *appearance = [CCNStatusItemWindowAppearance defaultAppearance];
    style.backgroundColor = [NSColor colorWithCalibratedRed:0.577 green:0.818 blue:0.130 alpha:1.000];
    style.cornerRadius = 115.0;
    appearance.presentationTransition = CCNPresentationTransitionSlideAndFade;
    [CCNStatusItem setWindowAppearance:appearance];
    
   [CCNStatusItem presentStatusItemWithImage:[NSImage imageNamed:@"statusbar-icon"]
                       contentViewController:[[ContentViewController alloc] initWithNibName:NSStringFromClass([ContentViewController class]) bundle:nil]];
    ...
}
```


## Some Side Notes

The statusItem window's frame size will be determined automatically by calling `preferedContentSize` on the `contentViewController`. So you shouldn't forget to set it to a reasonable value. Using XIB's for building the content a good war to do so is returning:

```Objective-C
- (CGSize)preferredContentSize {
    return self.view.frame.size;
}

```


## Requirements

`CCNStatusItem` was written using ARC and "modern" Objective-C 2. At the moment it has only support for OS X 10.10 Yosemite.


## Contribution

The code is provided as-is, and it is far off being complete or free of bugs. If you like this component feel free to support it. Make changes related to your needs, extend it or just use it in your own project. Pull-Requests and Feedbacks are very welcome. Just contact me at [phranck@cocoanaut.com](mailto:phranck@cocoanaut.com?Subject=[CCNStatusItem] Your component on Github) or send me a ping on Twitter [@TheCocoaNaut](http://twitter.com/TheCocoaNaut). 


## Documentation
The complete documentation you will find on [CocoaDocs](http://cocoadocs.org/docsets/CCNStatusItem/).


## License
This software is published under the [MIT License](http://cocoanaut.mit-license.org).


## Software that uses CCNStatusItem

* [Review Times](http://reviewtimes.cocoanaut.com) - A small Mac tool that shows you the calculated average of the review times for both the Mac App Store and the iOS App Store
