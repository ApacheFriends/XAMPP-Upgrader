//
//  RootHelper.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 04.09.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RootHelper : NSObject {
	BOOL __isHelperRunning;
	
	int __commFD;
}

+ (id) defaultRootHelper;

@property(readonly) BOOL isHelperRunning;
@property(readonly) int commFD;

- (BOOL) startHelperError:(NSError**)errorOrNil;
- (BOOL) stopHelperError:(NSError**)errorOrNil;

- (NSDictionary*) dispatchCommand:(NSString*)cmd 
						 withArgs:(NSDictionary*)args 
							error:(NSError**)errorOrNil;

@end
