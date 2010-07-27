//
//  Upgrader.m
//  XAMPP Upgrader
//
//  Created by Christian Speich on 26.07.10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "Upgrader.h"
#import "UpgradeContent.h"
#import "UpgradeErrors.h"

@interface Upgrader ()

- (BOOL) readXAMPPVersion;
- (BOOL) checkXAMPPVersion;

@end

@implementation Upgrader

@synthesize content=_content;
@synthesize path=_path;
@synthesize error=_error;
@synthesize delegate;
@synthesize installedXAMPPVersion;

- (id) initWithPath:(NSString*)path {
    if ((self = [super init])) {
        self.path = path;
    }
    
    return self;
}

- (void)dealloc {
    self.path = Nil;
    self.content = Nil;
    self.error = Nil;
    self.installedXAMPPVersion = Nil;
    
    [super dealloc];
}

- (BOOL) prepare
{
    NSError* error = Nil;
    
    [self.delegate setActionName:@"Prepare Upgrade..."];
    [self.delegate setActionDescription:@"Reading Upgrade Content..."];
    
    self.content = [UpgradeContent upgradeContentWithPath:self.path 
                                              andUpgrader:self
                                                    error:&error];
    
    if (!self.content) {
        self.error = error;
        return NO;
    }
    
    if (![self readXAMPPVersion])
        return NO;
    
    [self.delegate setActionDescription:@"Checking the installed XAMPP..."];
    if (![self checkXAMPPVersion])
        return NO;
    
    return YES;
}

- (BOOL) readXAMPPVersion
{
    NSError* error = Nil;
    NSString* path;
    NSString* version;
    
    path = [self.content.applicationPath 
            stringByAppendingPathComponent:self.content.versionFile];
    
    version = [NSString stringWithContentsOfFile:path 
                                    usedEncoding:NULL 
                                           error:&error];
    
    if (!version) {
        self.error = error;
        return NO;
    }
    
    self.installedXAMPPVersion = [version stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return YES;
}

- (BOOL) checkXAMPPVersion
{    
    // Well no need to upgrade, its already uptodate
    if ([self.installedXAMPPVersion isLike:self.content.version]) {
        self.error = [NSError errorWithDomain:UpgradeErrorDomain 
                                         code:errAlreadyUptToDate 
                                     userInfo:Nil];
        
        return NO;
    }
    
    // Woops you're even more uptodate than this upgrader
    if ([self.installedXAMPPVersion isGreaterThan:self.content.version]) {
        self.error = [NSError errorWithDomain:UpgradeErrorDomain 
                                         code:errNoDowngrade 
                                     userInfo:Nil];
        
        return NO;
    }
    
    // Well nope... we can't upgrade this thing, sorry
    if (![self.content.upgradeableVersions 
          containsObject:self.installedXAMPPVersion]) {
        self.error = [NSError errorWithDomain:UpgradeErrorDomain 
                                         code:errNotUpgradable 
                                     userInfo:Nil];
        
        return NO;
    }
    
    return YES;
}

- (BOOL) run
{
    return NO;
}

@end
