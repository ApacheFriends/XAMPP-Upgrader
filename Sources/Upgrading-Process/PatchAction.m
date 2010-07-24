/*
 
 XAMPP
 Copyright (C) 2010 by Apache Friends
 
 Authors of this file:
 - Christian Speich <kleinweby@apachefriends.org>
 
 This file is part of XAMPP.
 
 XAMPP is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 XAMPP is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with XAMPP.  If not, see <http://www.gnu.org/licenses/>.
 
 */

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
