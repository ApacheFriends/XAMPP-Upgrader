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

#import "Upgrader.h"
#import "UpgradingController.h"
#include <unistd.h>
#import "Action.h"

#import "UpgradeErrors.h"

@interface Upgrader(Steps)

- (BOOL) setupTempDir;
- (BOOL) tearDownTempDir;

- (BOOL) unpackContent;
- (BOOL) readContent;

@end

@interface Upgrader()

- (void) setApplicationPath:(NSString*)path;
- (void) setVersionFile:(NSString*)file;
- (void) setVersion:(NSString*)version;
- (void) setUpgradeableVersions:(NSSet*)versions;
- (void) setActions:(NSArray*)actions;
- (void) setUpgradeError:(NSError*)error;

@end


@implementation Upgrader

- (void) setDelegate:(id<UpgraderDelegateProtocol>)_delegate
{
	delegate = _delegate;
}

- (id<UpgraderDelegateProtocol>) delegate
{
	return delegate;
}

- (BOOL) upgrade
{	
	[[self delegate] setActionName:@"Prepare Upgrade…"];
	[[self delegate] setActionDescription:@"Reading upgrade content…"];

	/* First we need an temporary directory to unpack our upgrade in */
	if (![self setupTempDir]) {
	    return NO;	
	}
	
	/* Unpack the upgrade content to our temp dir */
	if (![self unpackContent]) {
		return NO;
	}
	
	if (![self readContent]) {
		return NO;
	}
	
	/* We're done with everything, remove the temp dir */
	if (![self tearDownTempDir]) {
		return NO;
	}
	
	NSLog(@"Temporary dir: %@", tempDir);
	
	[[self delegate] setProgress:0.1];
	
	for (int i = 1; i < 11; i++) {
		sleep(1);
		[[self delegate] setProgress:i*10.f];
	}
	
	return YES;
}

- (void) dealloc
{
	[tempDir release];
	
	[self setApplicationPath:Nil];
	[self setVersionFile:Nil];
	[self setVersion:Nil];
	[self setUpgradeableVersions:Nil];
	[self setActions:Nil];
    [self setUpgradeError:Nil];
	
	[super dealloc];
}


- (oneway void) quit
{
	NSLog(@"Quit...");
	exit(0);
}

- (NSString*) applicationPath
{
	return applicationPath;
}

- (NSString*) versionFile
{
	return versionFile;
}

- (NSString*) version
{
	return version;
}

- (NSSet*) upgradeableVersions
{
	return upgradeableVersions;
}

- (NSArray*) actions
{
	return actions;
}

- (NSError *)upgradeError {
    return upgradeError;
}

- (void) setApplicationPath:(NSString*)path
{
	[applicationPath release];
	applicationPath = [path copy];
}

- (void) setVersionFile:(NSString*)file
{
	[versionFile release];
	versionFile = [file copy];
}

- (void) setVersion:(NSString*)_version
{
	[version release];
	version = [_version copy];
}

- (void) setUpgradeableVersions:(NSSet*)versions
{
	[upgradeableVersions release];
	upgradeableVersions = [versions copy];
}

- (void) setActions:(NSArray*)_actions
{
	[actions release];
	actions = [_actions copy];
}

- (void)setUpgradeError:(NSError *)error
{
    [upgradeError release];
    upgradeError = [error retain];
}

@end

@implementation Upgrader(Steps)

- (BOOL) setupTempDir
{
	NSString *userTemp;
	NSString *bundleName;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// First we need to find the users temp dir.
	userTemp = NSTemporaryDirectory();
	
	if (!userTemp) {
		// Apple says this could fail...
		[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain
                                                  code:errGetTempDir 
                                              userInfo:Nil]];
		return NO;
	}
	
	bundleName = [[[NSBundle mainBundle] infoDictionary] 
				  objectForKey:@"CFBundleIdentifier"];
	
	// The temp dir we got is for every app that runs under that user
	// create an unique one for us (retain it for later use :))
	tempDir = [[userTemp stringByAppendingPathComponent:bundleName] retain];
	
	// If the folder already exists (because of a failed upgrade mainly)
	// remove it
	if ([fileManager fileExistsAtPath:tempDir]) {
		NSLog(@"WARNING! An old temp dir exists. An failed upgrade?!");
		
		if (![fileManager removeFileAtPath:tempDir handler:Nil]) {
			NSLog(@"Could not remove the old temp dir!");
			[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain 
                                                      code:errCreateTempDir 
                                                  userInfo:Nil]];
			return NO;
		}
	}
	
	
	// Finally create our temp dir
	if (![fileManager createDirectoryAtPath:tempDir attributes:Nil]) {
		[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain 
                                                  code:errCreateTempDir 
                                              userInfo:Nil]];
		return NO;
	}
	
	return YES;
}

- (BOOL) tearDownTempDir
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// Simply kill the temp dir here...
	if (![fileManager removeFileAtPath:tempDir handler:Nil]) {
		[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain
                                                  code:errRemoveTempDir
                                              userInfo:Nil]];
		return NO;
	}
	
	return YES;
}

- (BOOL) unpackContent
{
	NSTask *tarTask;
	NSString *upgradeBundlePath;
	
	upgradeBundlePath = [[NSBundle mainBundle] pathForResource:@"xampp"
														ofType:@"upgrade"];
		
	if (!upgradeBundlePath) {
		[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain 
                                                  code:errUpgradeBundleMissing 
                                              userInfo:Nil]];
		return NO;
	}
	
	tarTask = [[NSTask alloc] init];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"xfz", upgradeBundlePath, 
                           @"-C", tempDir, Nil]];
	
	[tarTask launch];
	[tarTask waitUntilExit];

	if ([tarTask terminationStatus] != 0) {
		[self setUpgradeError:[NSError errorWithDomain:UpgradeErrorDomain
                                                  code:errUnpackBundleFailed
                                              userInfo:Nil]];
		
		[tarTask release];
		return NO;
	}
	
	[tarTask release];
	return YES;
}

- (BOOL) readContent
{
	NSXMLParser *parser;
	NSURL *contentXML;
	
	contentXML = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:@"content.xml"]];
	
	NSLog(@"url %@", contentXML);
	
	// Setup some temporarlly vars
	elementStack = [[NSMutableArray alloc] init];
	
	parser = [[NSXMLParser alloc] initWithContentsOfURL:contentXML];
	
	[parser setDelegate:self];
	[parser parse];
	
	[elementStack release];
	elementStack = Nil;
	
	NSLog(@"appPath %@ versionFile %@ version %@ %@\n actions %i", applicationPath, versionFile, version, upgradeableVersions, [actions count]);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict
{
	[elementStack addObject:elementName];
	
	if ([elementName isEqualToString:@"application-path"] ||
		[elementName isEqualToString:@"version-file"] ||
		[elementName isEqualToString:@"version"]) {
		tempString = [[NSMutableString alloc] init];
	} else if ([elementName isEqualToString:@"upgradeable-versions"] ||
			   [elementName isEqualToString:@"actions"]) {
		tempArray = [[NSMutableArray alloc] init];
	} else if ([[Action knownActions] containsObject:elementName]) {
		tempAction = [[Action actionForName:elementName andAttributes:attributeDict] retain];
	} else {
		NSLog(@"Unhandeld %@", elementName);
	}

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (tempString) {
		[tempString appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	NSAssert([[elementStack lastObject] isEqualTo:elementName], 
             @"Wrong XML Element ended. NSXMLParser bug?!?");
	[elementStack removeLastObject];
	
	if ([elementName isEqualToString:@"application-path"]) {
		[self setApplicationPath:[tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		[tempString release];
		tempString = Nil;
	} else if ([elementName isEqualToString:@"version-file"]) {
		[self setVersionFile:[tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		[tempString release];
		tempString = Nil;
	} else if ([elementName isEqualToString:@"version"] && [[elementStack lastObject] isCaseInsensitiveLike:@"upgrade"]) {
		[self setVersion:[tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		[tempString release];
		tempString = Nil;
	} else if ([elementName isEqualToString:@"version"] && [[elementStack lastObject] isCaseInsensitiveLike:@"upgradeable-versions"]) {
		[tempArray addObject:[tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		[tempString release];
		tempString = Nil;
	} else if ([elementName isEqualToString:@"upgradeable-versions"]) {
		[self setUpgradeableVersions:[NSSet setWithArray:tempArray]];
		[tempArray release];
		tempArray = Nil;
	} else if ([elementName isEqualToString:@"actions"]) {
		[self setActions:tempArray];
		[tempArray release];
		tempArray = Nil;
	} else if ([[Action knownActions] containsObject:elementName]) {
		[tempArray addObject:tempAction];
		[tempAction release];
		tempAction = Nil;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"error %@", parseError);
}

@end
