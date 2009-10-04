//
//  main.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 02.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
		return -2000;
	}
	
	[[NSRunLoop currentRunLoop] run];
	
	[control release];
    [pool drain];
    return 0;
}
