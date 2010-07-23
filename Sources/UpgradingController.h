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

#import <Cocoa/Cocoa.h>

#import "UpgraderDelegateProtocol.h"

extern NSString* XUWelcomeScreen;
extern NSString* XUProgressScreen;

@interface UpgradingController : NSWindowController<UpgraderDelegateProtocol> {
	IBOutlet NSView*		contentView;
	IBOutlet NSView*		welcomeView;
	IBOutlet NSView*		progressView;
	NSDictionary*			views;
	
	/* Welcome View */
	IBOutlet NSTextView*	welcomeTextView;
	
	/* Progress View */
	IBOutlet NSProgressIndicator*progressIndicator;
	IBOutlet NSTextField*	progressText;
	IBOutlet NSTextField*	progressSubtext;
}

- (void) loadWelcomeView;
- (void) loadProgressView;
- (void) showView:(NSString*)view;

- (NSProgressIndicator*) progressIndicator;
- (NSTextField*) progressText;
- (NSTextField*) progressSubtext;

/* Upgrader Delegate */
- (void) setProgress:(double)progress;
- (void) setActionName:(NSString*)name;
- (void) setActionDescription:(NSString*)description;

- (IBAction) startUpgrade:(id)sender;

@end
