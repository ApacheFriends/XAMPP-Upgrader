//
//  AccessControl.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 04.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AccessControl.h"
#import "Upgrader.h"

@implementation AccessControl

- (id) init
{
	self = [super init];
	if (self != nil) {
		idleQuit = [[NSTimer scheduledTimerWithTimeInterval:10
													 target:self 
												   selector:@selector(idleQuit) 
												   userInfo:Nil 
													repeats:NO] retain];
	}
	return self;
}

- (BOOL) checkAuthorizationExternalForm:(AuthorizationExternalForm)form
{
	OSStatus status;
	AuthorizationRef authRef;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};
	
	status = AuthorizationCreateFromExternalForm(&form, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"AuthorizationCreateFromExternalForm failed with %i; Access Denied", status);
		return NO;
	}
	
	status = AuthorizationCopyRights(authRef, &rights, NULL, flags, NULL);
	
	if (status != errAuthorizationSuccess) {
		NSLog(@"AuthorizationCopyRights failed with %i; Access Denied", status);
		return NO;
	}
	
	return YES;
}

- (Upgrader*) newUpgraderWithAuthorizationExternalForm:(AuthorizationExternalForm)form
{
	if (![self checkAuthorizationExternalForm:form])
		return Nil;
	
	[idleQuit invalidate];
	[idleQuit release];
	idleQuit = Nil;
	
	return [[Upgrader alloc] init];
}

- (void) idleQuit
{
	NSLog(@"No access granted in the last 10 seconds. Quit...");
	exit(0);
}

@end
