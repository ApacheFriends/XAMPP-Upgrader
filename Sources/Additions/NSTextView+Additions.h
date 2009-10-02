//
//  NSTextView+Additions.h
//  XAMPP Upgrader
//
//  Created by Christian Speich on 01.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTextView (Additions)

- (float) heightToFitWithWidth:(float)width;
- (float) heightToFitWithWidth:(float)width andMaxHeight:(float)height;

@end
