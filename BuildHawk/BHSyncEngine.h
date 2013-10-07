//
//  BHSyncEngine.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSyncEngine : NSObject

+ (BHSyncEngine*)sharedEngine;
- (void)registerNSManagedObjectClassToSync:(Class)aClass;
@end
