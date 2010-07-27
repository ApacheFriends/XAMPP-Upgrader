//
//  UpgradeContent.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 26.07.10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Upgrader;

@interface UpgradeContent : NSObject {
@private
    NSString* path;
    NSError* error;
    
    NSString* tempDir;
        
    NSString* applicationPath;
	NSString* versionFile;
	NSString* version;
	NSSet* upgradeableVersions;
	NSArray* actionsTree;
    
    // Temporary variables fo XML parsing
    BOOL inUpgradeElement;
    NSMutableArray* parseStack;
    
    Upgrader* upgrader;
}

+ (id) upgradeContentWithPath:(NSString*)path
                  andUpgrader:(Upgrader*)upgrader
                        error:(NSError**)errorOrNil;
- (id) initWithPath:(NSString*)path
        andUpgrader:(Upgrader*)upgrader
              error:(NSError**)errorOrNil;

@property(copy) NSString* applicationPath;
@property(copy) NSString* versionFile;
@property(copy) NSString* version;
@property(copy) NSSet* upgradeableVersions;
@property(copy) NSArray* actionsTree;

- (NSArray*) actionsByEvaluatingConditions;

@property(readonly) NSString* path;

@property(copy) NSString* tempDir;
@property(copy) NSError* error;

@end
