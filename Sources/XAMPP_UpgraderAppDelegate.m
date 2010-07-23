/*
 
 XAMPP
 Copyright (C) 2010 by Apache Friends
 
 Authors of this file:
 - Christian Speich <kleinweby@apachefriends.org>
 
 This file is part of XAMPP.
 
 XAMPP is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 XAMPP is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with XAMPP.  If not, see <http://www.gnu.org/licenses/>.
 
 */

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
