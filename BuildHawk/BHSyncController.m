//
//  BHSyncController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSyncController.h"
#import "BHAppDelegate.h"
#import "Task+helper.h"
#import "Checklist+helper.h"
#import "Report+helper.h"

@implementation BHSyncController{
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSArray *tasks;
}

- (id)init {
    if (self = [super init]) {
        delegate = [UIApplication sharedApplication].delegate;
        manager = delegate.manager;
    }
    return self;
}

- (void)fetchObjectsThatNeedSyncing {
    tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
}


@end
