//
//  Action.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 22.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Action : NSObject {
}

+ (NSSet*) knownActions;
// Private
+ (NSDictionary*) actionsClasses;

+ (id) actionForName:(NSString*)name andAttributes:(NSDictionary*)attributes;

- (id) initWithAttributes:(NSDictionary*)attributes;

- (BOOL) canApply;
- (BOOL) applyWithError:(NSError**)errorOrNil;

@end
