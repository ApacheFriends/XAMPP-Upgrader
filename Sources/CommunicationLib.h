/*
 *  CommunicationLib.h
 *  XAMPP Upgrader
 *
 *  Created by Christian Speich on 06.09.10.
 *  Copyright 2010 Apple Inc. All rights reserved.
 *
 */

#include <CoreFoundation/CoreFoundation.h>

#define kBASDescriptorArrayKey "com.apple.dts.BetterAuthorizationSample.descriptors"

int BASReadDictioanaryTranslatingDescriptors(int fd, NSDictionary **dictPtr);
int BASWriteDictionaryAndDescriptors(NSDictionary* dict, int fd);
extern void BASCloseDescriptorArray(NSArray* descArray);
