//
//  XAMPP_UpgraderAppDelegate.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 30.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XAMPP_UpgraderAppDelegate.h"
#import "UpgradingController.h"

@implementation XAMPP_UpgraderAppDelegate

- (void)awakeFromNib {
	controller = [[UpgradingController alloc] initWithWindowNibName:@"UpgradeWindow"];
	[controller showWindow:self];
}

- (float) textHeightForString:(NSString*)anString withWidth:(double)width
{
	NSParameterAssert(anString != Nil);
	NSParameterAssert(width > 0);
	
	NSTextStorage *textStorage;
	NSTextContainer *textContainer;
	NSLayoutManager *layoutManager;
	
	textStorage = [[[NSTextStorage alloc] initWithString:anString] autorelease];
	textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, FLT_MAX)] autorelease];
	layoutManager = [[NSLayoutManager new] autorelease];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	//[textContainer setLineFragmentPadding:0.0];
	
	[textStorage addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont systemFontSize]]
						range:NSMakeRange(0, [textStorage length])];
	
	/* Force the layoutmanage to layout the string so we can access the height */
	(void) [layoutManager glyphRangeForTextContainer:textContainer];
	
	return NSHeight([layoutManager usedRectForTextContainer:textContainer]);
}

@end
