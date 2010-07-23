//
//  Action.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Action.h"
#import "PatchAction.h"
#import "MoveAction.h"

@implementation Action

+ (NSSet*) knownActions
{
	return [NSSet setWithArray:[[self actionsClasses] allKeys]];
}

// Private
+ (NSDictionary*) actionsClasses
{
	return [NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([PatchAction class]),@"patch", NSStringFromClass([MoveAction class]), @"move",Nil];
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
	
	[super dealloc];
}


- (BOOL) canApply
{
	return YES;
}

- (BOOL) applyWithError:(NSError**)errorOrNil
{
	return NO;
}

@end
