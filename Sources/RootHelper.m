//
//  RootHelper.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 04.09.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Security/Security.h>

#import "RootHelper.h"

@interface RootHelper(PRIVATE)

- (AuthorizationRef) authorizeWithError:(NSError**)error;

@end

@implementation RootHelper

@synthesize isHelperRunning=__isHelperRunning;
@synthesize commFD=__commFD;

+ (id) defaultRootHelper
{
	static id defaultRootHelper = Nil;
	
	if (defaultRootHelper == Nil) {
		defaultRootHelper = [[self alloc] init];
	}
	
	return defaultRootHelper;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		__isHelperRunning = NO;
		__commFD = -1;
	}
	return self;
}

- (void) dealloc
{
	if (self.isHelperRunning)
		NSLog(@"WARNING: Helper still running but Helper Class is beeing deallocated!");
	
	[super dealloc];
}

- (BOOL) startHelperError:(NSError**)errorOrNil
{
	AuthorizationRef authRef;
	NSString *helperTool;
	FILE *pipe = NULL;
	int status;
	char *args[] = {NULL};
	
	if (self.isHelperRunning)
		return YES;
	
	// First authorize the user
	authRef = [self authorizeWithError:errorOrNil];
	
	if (authRef == NULL) {
		
		return NO;
	}
	
	// Find the path for our helper tool
	helperTool = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"root-helper"];
	
	if (helperTool == Nil) {
		
		return NO;
	}
	
	// Now start it
	status = AuthorizationExecuteWithPrivileges(authRef, [helperTool fileSystemRepresentation], kAuthorizationFlagDefaults, args, &pipe);
	if (status != errAuthorizationSuccess) {
		if (errorOrNil)
			*errorOrNil = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
		return Nil;
	}
}

- (BOOL) stopHelperError:(NSError**)errorOrNil
{
}

@end

@implementation RootHelper(PRIVATE)

- (AuthorizationRef) authorizeWithError:(NSError**)error
{
	OSStatus status;
	AuthorizationRef authRef;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};
	
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authRef);
	
	if (status != errAuthorizationSuccess) {
		if (error != Nil) {
			if (status == errAuthorizationCanceled) {
				*error = [NSError errorWithDomain:NSCocoaErrorDomain 
											 code:NSUserCancelledError 
										 userInfo:Nil];
			}
			else {
				*error = [NSError errorWithDomain:NSOSStatusErrorDomain 
											 code:status 
										 userInfo:nil];
			}
		}
		
		return NULL;
	}
	
	flags  = kAuthorizationFlagDefaults;
	flags |= kAuthorizationFlagInteractionAllowed;
	flags |= kAuthorizationFlagPreAuthorize;
	flags |= kAuthorizationFlagExtendRights;
	
	status = AuthorizationCopyRights(authRef, &rights, NULL, flags, NULL);
	
	if (status != errAuthorizationSuccess) {
		if (error != Nil) {
			if (status == errAuthorizationCanceled) {
				*error = [NSError errorWithDomain:NSCocoaErrorDomain 
											 code:NSUserCancelledError 
										 userInfo:Nil];
			}
			else {
				*error = [NSError errorWithDomain:NSOSStatusErrorDomain 
											 code:status 
										 userInfo:nil];
			}
		}
		
		return NULL;
	}
	
	return authRef;
}

@end

