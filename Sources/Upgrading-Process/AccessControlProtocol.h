//
//  AccessControlProtocol.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 04.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Security/Security.h>

@class Upgrader;

@protocol AccessControlProtocol

- (Upgrader*) newUpgraderWithAuthorizationExternalForm:(AuthorizationExternalForm)form;

@end
