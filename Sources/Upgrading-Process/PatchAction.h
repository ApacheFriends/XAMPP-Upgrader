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

#import <Cocoa/Cocoa.h>
#import "Action.h"

typedef enum {
    UnknownPatchType=-1,
	BinaryPatch = 1,
	TextPatch = 2
} PatchType;

NSString* NSStringFromPatchType(PatchType type);
PatchType PatchTypeFromNSString(NSString* string);

@interface PatchAction : Action {
	NSString*	patchFile;
	NSString*	path;
    NSString*   sourceSHA1;
    NSString*   targetSHA1;
    
    PatchType   type;
}

@property(copy) NSString* patchFile;
@property(copy) NSString* path;
@property(copy) NSString* sourceSHA1;
@property(copy) NSString* targetSHA1;
@property PatchType type;

@end
