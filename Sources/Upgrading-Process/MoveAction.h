//
//  MoveAction.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"

@interface MoveAction : Action {
    NSString* sourcePath;
    NSString* targetPath;
}

- (NSString*) sourcePath;
- (NSString*) targetPath;

@end
