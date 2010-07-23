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
