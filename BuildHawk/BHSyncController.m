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
}

@synthesize tasks = _tasks;
@synthesize checklistItems = _checklistItems;
@synthesize reports = _reports;
@synthesize photos = _photos;

+ (id)sharedController {
    static BHSyncController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (id)init {
    if (self = [super init]) {
        delegate = [UIApplication sharedApplication].delegate;
        manager = delegate.manager;
    }
    return self;
}

- (void)fetchObjectsThatNeedSyncing {
    _tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _checklistItems = [ChecklistItem MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _reports = [Report MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _photos = [Photo MR_findByAttribute:@"identifier" withValue:@0 inContext:[NSManagedObjectContext MR_defaultContext]];
    NSLog(@"unsaved tasks: %d, checklist items: %d, reports: %d, photos: %d",_tasks.count, _checklistItems.count, _reports.count, _photos.count);
}

- (void)syncAll{
    [self fetchObjectsThatNeedSyncing];
    if (_tasks.count || _checklistItems.count || _reports.count || _photos.count){
        NSLog(@"should be syncing");
    }
}

@end
