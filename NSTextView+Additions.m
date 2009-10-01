//
//  NSTextView+Additions.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 01.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSTextView+Additions.h"


@implementation NSTextView (Additions)

- (float) heightToFitWithWidth:(float)width
{
	return [self heightToFitWithWidth:width andMaxHeight:FLT_MAX];
}

- (float) heightToFitWithWidth:(float)width andMaxHeight:(float)maxHeight
{
	NSTextStorage *textStorage;
	NSTextContainer *textContainer;
	NSLayoutManager *layoutManager;
	
	textStorage = [[[NSTextStorage alloc] initWithAttributedString:[self textStorage]] autorelease];
	textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, FLT_MAX)] autorelease];
	layoutManager = [[NSLayoutManager new] autorelease];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	/* Force the layoutmanage to layout the string so we can access the height */
	(void) [layoutManager glyphRangeForTextContainer:textContainer];
	
	return MIN(NSHeight([layoutManager usedRectForTextContainer:textContainer]), maxHeight);
}

@end
