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
	NSTextField*			progressTextField;
	NSTextField*			progressSubtextField;
}

- (void) setProgressIndicator:(NSProgressIndicator*)progressIndicator;
- (NSProgressIndicator*) progressIndicator;
- (void) setProgressTextField:(NSTextField*)progressTextField;
- (NSTextField*) progressTextField;
- (void) setProgressSubtextField:(NSTextField*)progressSubtextField;
- (NSTextField*) progressSubtextField;

- (NSError*) upgrade;

- (oneway void) quit;

@end
