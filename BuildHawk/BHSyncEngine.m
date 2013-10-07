//
//  BHSyncEngine.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHSyncEngine.h"

@interface BHSyncEngine()

@property (strong, nonatomic) NSMutableArray *registeredClassesToSync;

@end

@implementation BHSyncEngine

@synthesize registeredClassesToSync = _registeredClassesToSync;

+ (BHSyncEngine*)sharedEngine {
    static BHSyncEngine *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[BHSyncEngine alloc] init];
    });
    return sharedEngine;
}

- (void)registerNSManagedObjectClassToSync:(Class)aClass {
    if (!self.registeredClassesToSync) {
        self.registeredClassesToSync = [NSMutableArray array];
    }
    
    if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
        if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
            [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
        } else {
            NSLog(@"Unable to register %@ as it is already registered", NSStringFromClass(aClass));
        }
    } else {
        NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject", NSStringFromClass(aClass));
    }
    
}
@end
