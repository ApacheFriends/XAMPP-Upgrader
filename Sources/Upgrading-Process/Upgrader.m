//
//  Upgrader.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 02.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Upgrader.h"
#import "UpgradingController.h"
#include <unistd.h>

@implementation Upgrader

- (void) setProgressIndicator:(NSProgressIndicator*)indicator
{
	progressIndicator = indicator;
}

- (NSProgressIndicator*) progressIndicator
{
	return progressIndicator;
}

- (void) setProgressText:(NSTextField*)text
{
	progressText = text;
}

- (NSTextField*) progressText
{
	return progressText;
}

- (void) setProgressSubtext:(NSTextField*)subtext
{
	progressSubtext = subtext;
}

- (NSTextField*) progressSubtext
{
	return progressSubtext;
}

- (NSError*) upgrade
{
	NSError* error = Nil;
	
	[[self progressSubtext] setStringValue:@"Reading upgrade content…"];
	
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setDoubleValue:0.1f];
	
	for (int i = 1; i < 11; i++) {
		sleep(1);
		[[self progressIndicator] setDoubleValue:i*10.f];
	}
	
	return error;
}

- (oneway void) quit
{
	NSLog(@"Quit...");
	exit(0);
}

@end
