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

- (BOOL) checkAuthorizationRight:(char*)right 
                  inExternalForm:(AuthorizationExternalForm)form
{
	OSStatus status;
	AuthorizationRef authRef;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;
	AuthorizationItem items = {right, 0, NULL, 0};
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
    if (![self checkAuthorizationRight:kAuthorizationRightExecute inExternalForm:form])
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
