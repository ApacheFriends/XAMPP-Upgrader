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

#import "Action.h"
#import "PatchAction.h"
#import "MoveAction.h"

@implementation Action

@synthesize upgrader;

+ (NSSet*) knownActions
{
	return [NSSet setWithArray:[[self actionsClasses] allKeys]];
}

// Private
+ (NSDictionary*) actionsClasses
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
            NSStringFromClass([PatchAction class]),@"patch", 
            NSStringFromClass([MoveAction class]), @"move",
            Nil];
}

+ (id) actionForName:(NSString*)name andAttributes:(NSDictionary*)attributes
{
	NSString *class = [[self actionsClasses] objectForKey:name];
	
	NSAssert(class != Nil, @"Unknown Action");
	
	Class actionClass = NSClassFromString(class);
	
	return [[(Action*)[actionClass alloc] initWithAttributes:attributes] autorelease];
}

- (id) initWithAttributes:(NSDictionary*)attrs
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void) dealloc
{
	self.upgrader = Nil;
    
	[super dealloc];
}

- (BOOL) applyWithError:(NSError**)errorOrNil
{
	return NO;
}

@end
