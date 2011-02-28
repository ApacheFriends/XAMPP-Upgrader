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

static BOOL keepRunning = TRUE;

int sendCommunicationDescriptor(int *commFD) {
	NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
	int sockets[2];
	
	if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockets) < 0) {
        [dict setObject:@"Sockpair" forKey:@"error"];
        keepRunning = false;
    }
	else {
		[dict setObject:[NSArray arrayWithObject:[NSNumber numberWithInt:sockets[0]]] 
				 forKey:(NSString*)CFSTR(kBASDescriptorArrayKey)];
	}
	
	BASWriteDictionaryAndDescriptors(dict, *commFD);
	
	BASCloseDescriptorArray([dict objectForKey:(NSString*)CFSTR(kBASDescriptorArrayKey)]);
	[dict release];
	
	*commFD = sockets[1];
	
	return 0;
}


NSDictionary* handleRequest(NSDictionary* request) {
    
}

int main(int argc, char** argv) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int commFD = STDOUT_FILENO;
	
	sendCommunicationDescriptor(&commFD);
	
    while(keepRunning) {
        NSAutoreleasePool* loopPool = [[NSAutoreleasePool alloc] init];
        NSDictionary* request = Nil;
        NSDictionary* response = Nil;
        
        BASReadDictioanaryTranslatingDescriptors(commFD, &request);
        
        // Handle if request is nil
        
        response = handleRequest(request);
        
        // Handle if response is nil
        
        BASWriteDictionaryAndDescriptors(response, commFD);
        BASCloseDescriptorArray([response objectForKey:CFSTR(kBASDescriptorArrayKey)]);
        
        [loopPool release];
    }
    
	[pool release];
	
	return 0;
}