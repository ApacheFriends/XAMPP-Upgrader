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

#import "ErrorPresenter.h"


@implementation ErrorPresenter

@synthesize tableNames;
@synthesize genericErrorTableName;

- (id)init {
    if ((self = [super init])) {
        self.tableNames = [NSMutableDictionary dictionary];
        self.genericErrorTableName = @"Errors";
    }
    
    return self;
}

- (void) setTableName:(NSString*)name forDomain:(NSString*)errorDomain
{
    [self.tableNames setObject:name forKey:errorDomain];
}

- (BOOL) presentError:(NSError*)error
{
    NSString* tableName;
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* messageText = Nil;
    NSString* informativeText = Nil;
    NSString* errorCodeInfo = Nil;
    NSAlert* alert = [NSAlert alertWithError:error];
    
    // Look up the table for this error domain
    tableName = [self.tableNames objectForKey:[error domain]];
    // We have a localized (more) detailed version of this error
    // probbably in a file :)
    if (tableName) {
        NSInteger errorCode = abs([error code]);
        
        // Now we looks up the strings in the strings file
        // We start with the most specific match and get more loosly
        // each round:
        //  Error1032 and Error1032Info
        // then:
        //  Error103 and Error103Info
        // untill we found a message.
        
        while (errorCode > 0 &&
               (messageText == Nil || informativeText == Nil)) {
            NSString* key;
            
            key = [NSString stringWithFormat:@"Error%i", errorCode];
            
            if (messageText == Nil) {
                messageText = [bundle localizedStringForKey:key 
                                                      value:Nil 
                                                      table:tableName];
                
                // This returns key if key is not found
                // not very useful for us:
                if ([messageText isLike:key]) {
                    messageText = Nil;
                }
            }
            
            // The Info key
            key = [key stringByAppendingString:@"Info"];
            
            if (informativeText == Nil) {
                informativeText = [bundle localizedStringForKey:key 
                                                          value:Nil 
                                                          table:tableName];
                
                // This returns key if key is not found
                // not very useful for us:
                if ([informativeText isLike:key]) {
                    informativeText = Nil;
                }
            }
            
            // Remove the last diget from the errorcode
            errorCode /= 10;
        }
    }
    
    // An generic info text
    if (informativeText == Nil) {
        informativeText = [bundle localizedStringForKey:@"GenericErrorInfo" 
                                                  value:Nil
                                                  table:self.genericErrorTableName];
    }
    
    errorCodeInfo = [bundle localizedStringForKey:@"ErrorCode" 
                                            value:@"(%i)" 
                                            table:self.genericErrorTableName];
    errorCodeInfo = [NSString stringWithFormat:errorCodeInfo, [error code]];
    
    
    informativeText = [informativeText stringByAppendingFormat:@" %@", errorCodeInfo];
    
    if (messageText)
        [alert setMessageText:messageText];
    
    if (informativeText)
        [alert setInformativeText:informativeText];
    
    [alert runModal];
        
    // No, no recovery happend
    return NO;
}

- (void)dealloc {
    self.tableNames = Nil;
    self.genericErrorTableName = Nil;
    
    [super dealloc];
}

@end
