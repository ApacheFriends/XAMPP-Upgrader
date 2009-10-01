//
//  XAMPP_UpgraderAppDelegate.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 30.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UpgradingController;

@interface XAMPP_UpgraderAppDelegate : NSObject {
	UpgradingController* controller;
    NSWindow *window;
	IBOutlet NSTextView *textView;
}

@end
