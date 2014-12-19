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
#import "ChecklistItem+helper.h"
#import "Report+helper.h"

typedef void(^synchCompletion)(BOOL);

@implementation BHSyncController{
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
}

@synthesize tasks = _tasks;
@synthesize checklistItems = _checklistItems;
@synthesize reports = _reports;
@synthesize photos = _photos;
@synthesize synchCount = _synchCount;

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
        
        //run timer every 30 minutes
        [NSTimer scheduledTimerWithTimeInterval:1800 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)executeTimer {
    [self syncAll];
}

- (void)fetchObjectsThatNeedSyncing {
    _synchCount = 0;
    _tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _checklistItems = [ChecklistItem MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _reports = [Report MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    _photos = [Photo MR_findByAttribute:@"identifier" withValue:@0 inContext:[NSManagedObjectContext MR_defaultContext]];
    NSLog(@"Unsaved tasks: %lu, checklist items: %lu, reports: %lu, photos: %lu",(unsigned long)_tasks.count, (unsigned long)_checklistItems.count, (unsigned long)_reports.count, (unsigned long)_photos.count);
    
    _synchCount += _tasks.count;
    _synchCount += _checklistItems.count;
    _synchCount += _reports.count;
    _synchCount += _photos.count;
}

- (void)syncAll{
    [self fetchObjectsThatNeedSyncing];
    if (_synchCount <= 0){
        return;
    } else {
        NSString *updateString = (_synchCount == 1) ? @"1 object" : [NSString stringWithFormat:@"%d objects",_synchCount];
        [delegate displayStatusMessage:[NSString stringWithFormat:@"Updating %@...",updateString]];
    }
    
    if (_tasks.count && delegate.connected) {
        NSLog(@"Should be syncing %lu tasks",(unsigned long)_tasks.count);
        for (Task *task in _tasks){
            [task synchWithServer:^(BOOL completed) {
                _synchCount--;
                if (completed){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self updateSynchCount];
                    }];
                }
            }];
        }
    }
    
    if (_checklistItems.count){
        NSLog(@"Should be syncing %lu checklist items",(unsigned long)_checklistItems.count);
        for (ChecklistItem *item in _checklistItems){
            [item synchWithServer:^(BOOL completed) {
                _synchCount--;
                if (completed){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self updateSynchCount];
                    }];
                }
            }];
        }
    }
    
    if (_reports.count){
        NSLog(@"Should be syncing %lu reports",(unsigned long)_reports.count);
        for (Report *report in _reports){
            [report synchWithServer:^(BOOL completed) {
                _synchCount--;
                if (completed){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self updateSynchCount];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadReports" object:nil];
                    }];
                }
            }];
        }
    }
    
    if (_photos.count){
        NSLog(@"Should be syncing %lu photos",(unsigned long)_photos.count);
        for (Photo *photo in _photos){
            [photo synchWithServer:^(BOOL completed) {
                _synchCount--;
                if (completed){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self updateSynchCount];
                    }];
                }
            }];
        }
    }
}

- (void)update {
    [self fetchObjectsThatNeedSyncing];
    [self updateSynchCount];
}

- (void)updateStatusMessage:(SynchDirection)direction {
    switch (direction) {
        case kDecrement:
            _synchCount --;
            break;
        case kIncrement:
            _synchCount ++;
            break;
        default:
            break;
    }
    [self updateSynchCount];
}

- (void)updateSynchCount {
    if (_synchCount <= 0){
        [delegate removeStatusMessage];
    } else {
        if (delegate.connected){
            NSString *updateString = (_synchCount == 1) ? @"1 object" : [NSString stringWithFormat:@"%d objects",_synchCount];
            [delegate displayStatusMessage:[NSString stringWithFormat:@"Updating %@...",updateString]];
        } else {
            NSString *updateString = (_synchCount == 1) ? @"1 object needs" : [NSString stringWithFormat:@"%d objects need",_synchCount];
            [delegate displayStatusMessage:[NSString stringWithFormat:@"%@ to be synchronized",updateString]];
        }
    }
}

- (void)cancelSynch {
    NSArray *reports = [Report MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *checklistItems = [ChecklistItem MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        [report setSaved:@YES];
    }];
    [tasks enumerateObjectsUsingBlock:^(Task *task, NSUInteger idx, BOOL *stop) {
        [task setSaved:@YES];
    }];
    [checklistItems enumerateObjectsUsingBlock:^(ChecklistItem *item, NSUInteger idx, BOOL *stop) {
        [item setSaved:@YES];
    }];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self updateSynchCount];
}

@end
