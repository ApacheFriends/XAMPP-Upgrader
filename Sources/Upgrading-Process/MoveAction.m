//
//  MoveAction.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MoveAction.h"

@interface MoveAction()

- (void) setSourcePath:(NSString*)path;
- (void) setTargetPath:(NSString*)path;

@end

@implementation MoveAction

- (NSString*) sourcePath
{
    return sourcePath;
}

- (void) setSourcePath:(NSString *)path
{
    [sourcePath release];
    sourcePath = [path copy];
}

- (NSString *)targetPath
{
    return targetPath;
}

- (void)setTargetPath:(NSString *)path
{
    [targetPath release];
    targetPath = [path copy];
}

- (id) initWithAttributes:(NSDictionary*)attrs
{
	self = [super initWithAttributes:attrs];
	if (self != nil) {
        [self setTargetPath:[attrs objectForKey:@"target-path"]];
        [self setSourcePath:[attrs objectForKey:@"source-path"]];
	}
	return self;
}

- (void)dealloc {
    [self setSourcePath:Nil];
    [self setTargetPath:Nil];
    
    [super dealloc];
}

@end
