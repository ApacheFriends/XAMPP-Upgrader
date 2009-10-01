//
//  UpgradingController.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 30.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UpgradingController.h"
#import "NSTextView+Additions.h"

NSString* XUWelcomeScreen = @"XUWelcomeScreen";
NSString* XUProgressScreen = @"XUProgressScreen";

@implementation UpgradingController

- (void)awakeFromNib {
	/* Set the background of our window to white. */
	[[self window] setBackgroundColor:[NSColor whiteColor]];
	
	/* And now load all view. */
	[self loadWelcomeView];
	[self loadProgressView];
	
	/* Show the first view */
	[self showView:XUWelcomeScreen];
}

- (void) loadWelcomeView
{
	NSAttributedString* string;
	
	string = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Welcome" ofType:@"rtfd"] documentAttributes:Nil];
	
	[[welcomeTextView textStorage] setAttributedString:string];
	
	[welcomeView setFrameSize:NSMakeSize(NSWidth([welcomeView frame]), 
										 NSHeight([welcomeView frame]) 
										 - NSHeight([welcomeTextView frame]) 
										 + [welcomeTextView heightToFitWithWidth:NSWidth([welcomeTextView frame])])];
}

- (void) loadProgressView
{
	[progressIndicator startAnimation:Nil];
	[progressText setStringValue:@"Prepare Upgrade…"];
}

- (void) showView:(NSString *)name
{
	NSParameterAssert(name != Nil);
	
	/* Look for our content view. */
	NSDictionary* views = [NSDictionary dictionaryWithObjectsAndKeys:welcomeView, XUWelcomeScreen,
						   progressView, XUProgressScreen,
						   Nil];
	NSView* view = [views objectForKey:name];
	NSParameterAssert(view != Nil);
	
	/* Remove all old views */
	[[contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

	/* Find out the paddings of the content view */
	float paddingTop = 0.f;
	float paddingBottom = 0.f;
	
	paddingBottom = [contentView frame].origin.y;
	paddingTop = NSHeight([[self window] frame]) - NSHeight([contentView frame]) - paddingBottom;

	float newHeight = NSHeight([view frame]) + paddingTop + paddingBottom;
	
	[[self window] setFrame:NSMakeRect([[self window] frame].origin.x,
									   [[self window] frame].origin.y - newHeight + NSHeight([[self window] frame]),
									   NSWidth([[self window] frame]),
									   newHeight)
					display:YES
					animate:YES];
	
	[contentView addSubview:view];
}

- (IBAction) startUpgrade:(id)sender
{
	[self showView:XUProgressScreen];
}

@end
