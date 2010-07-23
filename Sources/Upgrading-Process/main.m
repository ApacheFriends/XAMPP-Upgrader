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

#import <Foundation/Foundation.h>
#import "AccessControl.h"
#include <unistd.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];	
	NSConnection *connection;
	AccessControl* control;

	/* To be sure that some subprocesses like bash don't
	   drop thier root rights */
	setuid(0);
	
	control = [[AccessControl alloc] init];
		
	connection = [NSConnection defaultConnection];
	[connection setRootObject:[NSProtocolChecker protocolCheckerWithTarget:control 
																  protocol:@protocol(AccessControlProtocol)]];
	
	if (![connection registerName:@"xampp-upgrader"]) {
		NSLog(@"Can't register server name");
        [control release];
		return -2000;
	}
	
	[[NSRunLoop currentRunLoop] run];
	
	[control release];
    [pool drain];
    return 0;
}
