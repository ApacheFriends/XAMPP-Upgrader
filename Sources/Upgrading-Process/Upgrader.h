//
//  Upgrader.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 02.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UpgradingController;

@interface Upgrader : NSObject {
	NSProgressIndicator*	progressIndicator;
	NSTextField*			progressText;
	NSTextField*			progressSubtext;
}

- (void) setProgressIndicator:(NSProgressIndicator*)progressIndicator;
- (NSProgressIndicator*) progressIndicator;
- (void) setProgressText:(NSTextField*)progressText;
- (NSTextField*) progressText;
- (void) setProgressSubtext:(NSTextField*)progressSubtext;
- (NSTextField*) progressSubtext;

- (NSError*) upgrade;

- (oneway void) quit;

@end
