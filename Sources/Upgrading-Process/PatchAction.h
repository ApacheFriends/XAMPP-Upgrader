//
//  PatchAction.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"

typedef enum {
	BinaryPatch,
	TextPatch
} PatchType;

@interface PatchAction : Action {
	NSString*	patchFile;
	NSString*	path;
	PatchType   type;
}

- (NSString*) patchFile;
- (NSString*) path;
- (PatchType) type;

@end
