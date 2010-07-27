//
//  UpgradeContent.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 26.07.10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "UpgradeContent.h"
#import "UpgradeErrors.h"

#import "Action.h"

@interface UpgradeContent (PRIVATE)

- (BOOL) setupTempDir;
- (BOOL) tearDownTempDir;

- (BOOL) unpackContent;
- (BOOL) parseContent;

@end

@implementation UpgradeContent

@synthesize applicationPath;
@synthesize versionFile;
@synthesize version;
@synthesize upgradeableVersions;
@synthesize actionsTree;
@synthesize tempDir;
@synthesize error;
@synthesize path;

+ (id)upgradeContentWithPath:(NSString *)path
                 andUpgrader:(Upgrader*)upgrader
                       error:(NSError **)errorOrNil
{
    return [[[self alloc] initWithPath:path
                           andUpgrader:upgrader 
                                 error:errorOrNil] 
            autorelease];
}

- (id) initWithPath:(NSString*)_path
        andUpgrader:(Upgrader*)_upgrader
              error:(NSError**)errorOrNil
{
    if ((self = [super init])) {
        // Initialization code here.
        path = [_path copy];
        upgrader = _upgrader;
        
        if (![self setupTempDir]) {
            if (errorOrNil)
                *errorOrNil = self.error;
            [self release];
            return Nil;
        }
        
        if (![self unpackContent]) {
            if (errorOrNil)
                *errorOrNil = self.error;
            [self release];
            return Nil;
        }
        
        if (![self parseContent]) {
            if (errorOrNil)
                *errorOrNil = self.error;
            [self release];
            return Nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    [self tearDownTempDir];
    
    [path release];
    
    self.applicationPath = Nil;
    self.versionFile = Nil;
    self.version = Nil;
    self.upgradeableVersions = Nil;
    self.actionsTree = Nil;
    
    [super dealloc];
}

- (NSArray*) actionsByEvaluatingConditions
{
    // Currently we don't support conditions
    // so we just return the tree here
    return self.actionsTree;
}

@end

@implementation UpgradeContent (PRIVATE)

- (BOOL) setupTempDir
{
	NSString *userTemp;
	NSString *bundleName;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// First we need to find the users temp dir.
	userTemp = NSTemporaryDirectory();
	
	if (!userTemp) {
		// Apple says this could fail...
		self.error = [NSError errorWithDomain:UpgradeErrorDomain
                                         code:errGetTempDir
                                     userInfo:Nil];
		return NO;
	}
	
	bundleName = [[[NSBundle mainBundle] infoDictionary] 
				  objectForKey:@"CFBundleIdentifier"];
	
	// The temp dir we got is for every app that runs under that user
	// create an unique one for us (retain it for later use :))
	self.tempDir = [userTemp stringByAppendingPathComponent:bundleName];
	
	// If the folder already exists (because of a failed upgrade mainly)
	// remove it
	if ([fileManager fileExistsAtPath:self.tempDir]) {
		NSLog(@"WARNING! An old temp dir exists. An failed upgrade?!");
		
		if (![fileManager removeFileAtPath:self.tempDir handler:Nil]) {
			NSLog(@"Could not remove the old temp dir!");
			self.error = [NSError errorWithDomain:UpgradeErrorDomain
                                             code:errCreateTempDir
                                         userInfo:Nil];
			return NO;
		}
	}
	
	
	// Finally create our temp dir
	if (![fileManager createDirectoryAtPath:self.tempDir attributes:Nil]) {
		self.error = [NSError errorWithDomain:UpgradeErrorDomain
                                         code:errCreateTempDir
                                     userInfo:Nil];
		return NO;
	}
	
	return YES;
}

- (BOOL) tearDownTempDir
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// Simply kill the temp dir here...
	[fileManager removeFileAtPath:self.tempDir handler:Nil];
	
	return YES;
}

- (BOOL) unpackContent
{
	NSTask *tarTask;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
	if (![fileManager fileExistsAtPath:self.path]) {
		self.error = [NSError errorWithDomain:UpgradeErrorDomain
                                         code:errUpgradeBundleMissing
                                     userInfo:Nil];
		return NO;
	}
	
	tarTask = [[NSTask alloc] init];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"xfz", self.path, 
                           @"-C", self.tempDir, Nil]];
	
	[tarTask launch];
	[tarTask waitUntilExit];
    
	if ([tarTask terminationStatus] != 0) {
		self.error = [NSError errorWithDomain:UpgradeErrorDomain
                                         code:errUnpackBundleFailed
                                     userInfo:Nil];
		
		[tarTask release];
		return NO;
	}
	
	[tarTask release];
	return YES;
}

- (BOOL)parseContent
{
    NSXMLParser *parser;
	NSURL *contentXML;
	
	contentXML = [NSURL fileURLWithPath:[self.tempDir stringByAppendingPathComponent:@"content.xml"]];
	
	NSLog(@"url %@", contentXML);
	
	parser = [[NSXMLParser alloc] initWithContentsOfURL:contentXML];
	
	[parser setDelegate:self];
    
    inUpgradeElement = NO;
    parseStack = [[NSMutableArray alloc] init];
    
	if (![parser parse]) {
        // Dirty for now
        self.error = [parser parserError];
        [parser release];
        return NO;
    }
    
    if ([parseStack count] > 0) {
        NSLog(@"Woops there are still objects on the parseStack: %@", parseStack);
    }
    [parseStack release];
    parseStack = Nil;
    
    NSLog(@"%@ %@ %@ %@ %i", self.applicationPath, self.versionFile, self.version, self.upgradeableVersions, [self.actionsTree count]);
    
    [parser release];
    return YES;
}

#pragma mark Parser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict
{
    if ([elementName isLike:@"upgrade"]) {
        NSString* contentVersion = [attributeDict objectForKey:@"version"];
        
        if (![contentVersion isLike:@"1.0"]) {
            NSLog(@"The XML version is %@ but should be 1.0! Abort...", 
                  contentVersion);
            [parser abortParsing];
        }
        
        inUpgradeElement = YES;
        
        // To make it short
        return;
    }
    
    if (!inUpgradeElement) {
        NSLog(@"outside of upgrade");
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:@"application-path"] ||
		[elementName isEqualToString:@"version-file"] ||
		[elementName isEqualToString:@"version"]) {
		[parseStack addObject:[NSMutableString string]];
	} else if ([elementName isEqualToString:@"upgradeable-versions"] ||
			   [elementName isEqualToString:@"actions"]) {
		[parseStack addObject:[NSMutableArray array]];
        
    } else if ([[Action knownActions] containsObject:elementName]) {
        Action* action = [Action actionForName:elementName 
                                 andAttributes:attributeDict];
        action.upgrader = upgrader;
		[parseStack addObject:action];
	} else {
        NSLog(@"element %@ not handeld", elementName);
        [parser abortParsing];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ([[parseStack lastObject] respondsToSelector:@selector(appendString:)]) {
		[[parseStack lastObject] appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    id obj;
    
    if ([elementName isLike:@"upgrade"]) {
        inUpgradeElement = NO;
        
        // To make it short
        return;
    }
    
    // We pop the last object of the stack
    obj = [parseStack lastObject];
    [parseStack removeLastObject];
    
    // There is still something on the stack
    // we don't have a root object now so add it
    // to its superseeding element
    if ([parseStack count] > 0) {
        NSMutableArray* array = [parseStack lastObject];
        
        [array addObject:obj];
    } else if ([elementName isEqualToString:@"application-path"]) {
        self.applicationPath = [(NSString*)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else if ([elementName isEqualToString:@"version-file"]) {
		self.versionFile = [(NSString*)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else if ([elementName isEqualToString:@"version"]) {
		self.version = [(NSString*)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else if ([elementName isEqualToString:@"upgradeable-versions"]) {
        self.upgradeableVersions = [NSSet setWithArray:obj];
	} else if ([elementName isEqualToString:@"actions"]) {
        self.actionsTree = obj;
	}
}

@end
