//
//  Upgrader.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 26.07.10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UpgraderDelegateProtocol.h"

@class UpgradeContent;

@interface Upgrader : NSObject {
@private
    UpgradeContent* _content;
    NSString* _path;
    
    NSError* _error;
    
    id<UpgraderDelegateProtocol> delegate;
    
    NSString* installedXAMPPVersion;
}

@property(retain) UpgradeContent* content;
@property(copy) NSString* path;
@property(retain) NSError* error;

@property(copy) NSString* installedXAMPPVersion;

@property(assign) id<UpgraderDelegateProtocol> delegate;

- (id) initWithPath:(NSString*)path;

- (BOOL) prepare;
- (BOOL) run;

@end
