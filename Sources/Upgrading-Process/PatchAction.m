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

NSString* NSStringFromPatchType(PatchType type)
{
    switch(type) {
        case BinaryPatch:
            return @"binary";
            break;
        case TextPatch:
            return @"text";
            break;
        case UnknownPatchType:
            return Nil;
    }
    
    return Nil;
}

PatchType PatchTypeFromNSString(NSString* string)
{
    if ([string isLike:@"binary"]) {
        return BinaryPatch;
    }
    else if ([string isLike:@"text"]) {
        return TextPatch;
    }
    else {
        return UnknownPatchType;
    }
}

@implementation PatchAction

@synthesize patchFile;
@synthesize path;
@synthesize sourceSHA1;
@synthesize targetSHA1;
@synthesize type;

- (id) initWithAttributes:(NSDictionary*)attrs
{
	self = [super initWithAttributes:attrs];
	if (self != nil) {
        /* Required stuff */
		self.patchFile = [attrs objectForKey:@"patch-file"];
		self.path = [attrs objectForKey:@"path"];
        self.type = PatchTypeFromNSString([attrs objectForKey:@"type"]);
		
        /* Optional stuff */
        self.sourceSHA1 = [attrs objectForKey:@"source-sha1"];
        self.targetSHA1 = [attrs objectForKey:@"target-sha1"];
	}
	return self;
}

- (void)dealloc {
    self.patchFile = Nil;
    self.path = Nil;
    self.sourceSHA1 = Nil;
    self.targetSHA1 = Nil;
    
    [super dealloc];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"<%@(%p) file=%@ path=%@>", [self className], self, [self patchFile], [self path]];
}

@end