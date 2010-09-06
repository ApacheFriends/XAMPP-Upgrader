/*
 *  root-helper.m
 *  XAMPP Upgrader
 *
 *  Created by Christian Speich on 06.09.10.
 *  Copyright 2010 Apple Inc. All rights reserved.
 *
 */

#import "CommunicationLib.h"

#import<Foundation/Foundation.h>
#include <sys/socket.h>

int sendCommunicationDescriptor(int *commFD) {
	NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
	int sockets[2];
	
	if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockets) < 0) {
        [dict setObject:@"Sockpair" forKey:@"error"];
    }
	else {
		[dict setObject:[NSArray arrayWithObject:[NSNumber numberWithInt:sockets[0]]] 
				 forKey:CFSTR(kBASDescriptorArrayKey)];
	}
	
	BASWriteDictionaryAndDescriptors(dict, *commFD);
	
	BASCloseDescriptorArray([dict objectForKey:CFSTR(kBASDescriptorArrayKey)]);
	[dict release];
	
	*commFD = sockets[1];
	
	return 0;
}

int main(int argc, char** argv) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int commFD = STDOUT_FILENO;
	
	sendCommunicationDescriptor(&commFD);
	
	[pool release];
	
	return 0;
}