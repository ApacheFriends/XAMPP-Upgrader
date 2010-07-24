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
