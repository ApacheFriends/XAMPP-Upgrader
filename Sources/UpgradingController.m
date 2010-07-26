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

#include <Security/Security.h>
#include <unistd.h>

#import "UpgradingController.h"
#import "NSTextView+Additions.h"
#import "NSObject+Additions.h"
#import "Upgrader.h"
#import "AccessControlProtocol.h"

#import "UpgradeErrors.h"
#import "ErrorPresenter.h"

NSString* XUWelcomeScreen = @"XUWelcomeScreen";
NSString* XUProgressScreen = @"XUProgressScreen";

@interface UpgradingController (UPGRARDE)

- (void) upgrade;
- (Upgrader*) newUpgradeHelperWithError:(NSError**)error;

- (void) handleError:(NSError*)error;
- (AuthorizationRef) authorizeWithError:(NSError**)error;

@end


@implementation UpgradingController

- (void) dealloc
{
	[views release];
	
	[super dealloc];
}

- (NSProgressIndicator*) progressIndicator
{
	return [progressIndicator mainThreadProxy];
}

- (NSTextField*) progressText
{
	return [progressText mainThreadProxy];
}

- (NSTextField*) progressSubtext
{
	return [progressSubtext mainThreadProxy];
}

- (void)awakeFromNib {
	/* Set the background of our window to white. */
	[[self window] setBackgroundColor:[NSColor whiteColor]];
	
	/* And now load all view. */
	[self loadWelcomeView];
	[self loadProgressView];
	
	/* Store an array which all views. For easier use :) */
	views = [[NSDictionary dictionaryWithObjectsAndKeys:welcomeView, XUWelcomeScreen,
			  progressView, XUProgressScreen,
			  Nil] retain];
	
	/* Show the first view */
	[self showView:XUWelcomeScreen];
}

- (void) loadWelcomeView
{
	NSAttributedString* string;
	
	string = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Welcome" ofType:@"rtfd"] 
								   documentAttributes:Nil];
	
	[[welcomeTextView textStorage] setAttributedString:string];
	
	[welcomeView setFrameSize:NSMakeSize(NSWidth([welcomeView frame]), 
										 NSHeight([welcomeView frame]) 
										 - NSHeight([welcomeTextView frame]) 
										 + [welcomeTextView heightToFitWithWidth:NSWidth([welcomeTextView frame])])];
	
	[string release];
}

- (void) loadProgressView
{
	[progressIndicator startAnimation:Nil];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressText setStringValue:@"Prepare Upgrade…"];
}

- (void) showView:(NSString *)name
{
	float paddingTop;
	float paddingBottom;
	float newHeight;
	NSView* view;
	
	NSParameterAssert(name != Nil);
	
	/* Look for our content view. */
	view = [views objectForKey:name];
	NSParameterAssert(view != Nil);
	
	/* Remove all old views */
	[[contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

	/* Find out the paddings of the content view */
	paddingBottom = [contentView frame].origin.y;
	paddingTop = NSHeight([[self window] frame]) - NSHeight([contentView frame]) - paddingBottom;
	newHeight = NSHeight([view frame]) + paddingTop + paddingBottom;
	
	[[self window] setFrame:NSMakeRect([[self window] frame].origin.x,
									   [[self window] frame].origin.y - newHeight + NSHeight([[self window] frame]),
									   NSWidth([[self window] frame]),
									   newHeight)
					display:YES
					animate:YES];
	
	[contentView addSubview:view];
}

- (void) setProgress:(double)progress
{
	if (progress < 0.f) {
		[progressIndicator setIndeterminate:YES];
	}
	else {
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setDoubleValue:progress];
	}

}

- (void) setActionName:(NSString*)name
{
	[progressText setStringValue:name];
}

- (void) setActionDescription:(NSString*)description
{
	[progressSubtext setStringValue:description];
}

- (IBAction) startUpgrade:(id)sender
{
	/* Show the progress screen */
	[self showView:XUProgressScreen];
	
	/* And now start the Thread which handels the real upgrade */
	[NSThread detachNewThreadSelector:@selector(upgrade)
							 toTarget:self 
						   withObject:Nil];
}

@end

@implementation UpgradingController (UPGRARDE)

- (void) upgrade
{
	/* We're here in a new thread so we need our own Pool ;) */
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSError* error = Nil;
	Upgrader* upgrader;
    
	/* Starting our helper process that runs as root */
	[[self progressSubtext] setStringValue:NSLocalizedStringFromTable(@"Authorize",
																	  @"Upgrade",
																	  @"Action description displayed when the user is asked to authorize.")];
	upgrader = [self newUpgradeHelperWithError:&error];
	if (!upgrader) {
		[self handleError:error];
		[pool release];
		return;
	}
	
	@try {
		/* Ok, we now have our Upgrader process. */
		
		[upgrader setDelegate:self];
		
		// Run the real upgrade
		if (![upgrader upgrade])
			[self handleError:[upgrader upgradeError]];
		
	}
	@catch (NSException * e) {
		// TODO: Error handling
		NSLog(@"Got %@", e);
	}
	@finally {
		[upgrader quit];
		[[self mainThreadProxy] showView:XUWelcomeScreen];
		[pool release];
	}
}

- (Upgrader*) newUpgradeHelperWithError:(NSError**)error
{
	OSStatus status;
	AuthorizationRef authRef;
	NSString *commandoPath;
	NSConnection* connection;
	AuthorizationExternalForm extForm;
	char *args[] = { NULL };
	
	id<AccessControlProtocol> accessControl;
	Upgrader* upgrader;
	
	/* Authorize the user */
	authRef = [self authorizeWithError:error];
	if (authRef == NULL) {
		return Nil;
	}

	/* Get the full path for our helper tool */
	commandoPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"xampp-upgrader"];
	if (!commandoPath) {
		if (error)
			*error = [NSError errorWithDomain:UpgradeErrorDomain 
										 code:errUpgradeHelperMissing 
									 userInfo:Nil];
		return Nil;
	}

	/* Start our littel helper tool as root */
	status = AuthorizationExecuteWithPrivileges(authRef, [commandoPath fileSystemRepresentation], kAuthorizationFlagDefaults, args, NULL);
	if (status != errAuthorizationSuccess) {
		if (error)
			*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
		return Nil;
	}
	
	/* Our helper process has now startet successful now we're trying to get an connection
	   to it */
	for (int i = 0; i < 200; i++) {
		usleep(10000);
		connection = [NSConnection connectionWithRegisteredName:@"xampp-upgrader"
														   host:nil];
		if (connection != Nil) {
			NSLog(@"Got the connection to the helper after %i trys", i);
			break;
		}
	}
	
	/* Woops, still no connection? -  Not so good */
	if (!connection) {
		if (error)
			*error = [NSError errorWithDomain:UpgradeErrorDomain 
										 code:errConnectUpgradeHelper 
									 userInfo:Nil];
		return Nil;
	}
	
	/* Get the access control object */
	accessControl = (id<AccessControlProtocol>)[connection rootProxy];
	if (!accessControl) {
		if (error)
			*error = [NSError errorWithDomain:UpgradeErrorDomain 
										 code:errAccessControlGet 
									 userInfo:Nil];
		return Nil;
	}

	/* Ok, now authorize against the helper process
	   to proof that we really have the root privileges */
	// Make our Authorization external
	status = AuthorizationMakeExternalForm(authRef, &extForm);
	if (status != errAuthorizationSuccess) {
		if (error != Nil)
			//TODO: Make nicer message
			*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
		return Nil;
	}
	
	// And now get the upgrader object
	/* TODO: We should pass an special xampp-upgrader right instand of the kAuthorizationRightExecute
	   to prevent bad processes that may listening on the xampp-control name get's this execute right
	   and start's root processes even if it is not allowed to */
	upgrader = [accessControl newUpgraderWithAuthorizationExternalForm:extForm];
	if (!upgrader) {
		if (error)
			*error = [NSError errorWithDomain:UpgradeErrorDomain 
										 code:errAccessControlDenied 
									 userInfo:Nil];
		return Nil;
	}
		
	return upgrader;
}

- (void) handleError:(NSError*)error
{
	if ([[error domain] isEqualToString:NSCocoaErrorDomain]
		&& [error code] == NSUserCancelledError) {
		[self showView:XUWelcomeScreen];
	}
	ErrorPresenter* presenter = [[ErrorPresenter alloc] init];
    
    [presenter setTableName:@"Errors" forDomain:UpgradeErrorDomain];
    
    [presenter presentError:error];
    
    [presenter release];
    
	NSLog(@"Error: %@", error);
}

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
