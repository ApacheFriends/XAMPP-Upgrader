//
//  PatchAction.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PatchAction.h"

@interface PatchAction()

- (void) setPatchFile:(NSString*)_file;
- (void) setPath:(NSString*)_path;
- (void) setType:(PatchType)_type;

@end


@implementation PatchAction

- (NSString*) patchFile
{
	return patchFile;
}

- (void) setPatchFile:(NSString*)_file
{
	[patchFile release];
	patchFile = [_file copy];
}

- (NSString*) path
{
	return path;
}

- (void) setPath:(NSString*)_path
{
	[path release];
	path = [_path copy];
}

- (PatchType) type
{
	return type;
}

- (void) setType:(PatchType)_type
{
	type = _type;
}

- (id) initWithAttributes:(NSDictionary*)attrs
{
	self = [super initWithAttributes:attrs];
	if (self != nil) {
		[self setPatchFile:[attrs objectForKey:@"patch-file"]];
		[self setPath:[attrs objectForKey:@"path"]];
		if ([[attrs objectForKey:@"type"] isCaseInsensitiveLike:@"text"]) {
			[self setType:TextPatch];
		} else if ([[attrs objectForKey:@"type"] isCaseInsensitiveLike:@"binary"]) {
			[self setType:BinaryPatch];
		} else {
			// TODO: Errorhandling
		}
	}
	return self;
}

- (void)dealloc {
    [self setPatchFile:Nil];
    [self setPath:Nil];
    
    [super dealloc];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"<%@(%p) file=%@ path=%@>", [self className], self, [self patchFile], [self path]];
}

@end
