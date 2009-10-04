//
//  AccessControl.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 04.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessControlProtocol.h"

@interface AccessControl : NSObject<AccessControlProtocol> {
	NSTimer* idleQuit;
}

- (BOOL) checkAuthorizationExternalForm:(AuthorizationExternalForm)form;

@end
