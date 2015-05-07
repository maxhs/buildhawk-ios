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
#import "Comment+helper.h"
#import "Reminder+helper.h"

typedef void(^synchCompletion)(BOOL);

@implementation BHSyncController{
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL synching;
}

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
        synching = NO;
        //run timer every 30 minutes
        [NSTimer scheduledTimerWithTimeInterval:1800 target:self selector:@selector(executeTimer) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)executeTimer {
    [self syncAll];
}

- (void)fetchObjectsThatNeedSyncing {
    self.synchCount = 0;
    self.tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.checklistItems = [ChecklistItem MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.reports = [Report MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.photos = [Photo MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.users = [User MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.reminders = [Reminder MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.comments = [Comment MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.projects = [Project MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    self.synchCount += self.tasks.count;
    self.synchCount += self.checklistItems.count;
    self.synchCount += self.reports.count;
    self.synchCount += self.photos.count;
    self.synchCount += self.users.count;
    self.synchCount += self.reminders.count;
    self.synchCount += self.comments.count;
    self.synchCount += self.projects.count;
}

- (void)syncAll{
    [self fetchObjectsThatNeedSyncing];
    if (synching) return;
    if (self.synchCount <= 0 || !delegate.connected){
        return;
    } else {
        NSString *updateString = (_synchCount == 1) ? @"1 object" : [NSString stringWithFormat:@"%lu objects",(unsigned long)self.synchCount];
        [delegate displayStatusMessage:[NSString stringWithFormat:@"Updating %@. Tap for progress.",updateString]];
    }
    
    if (self.tasks.count && delegate.connected) {
        NSLog(@"Should be syncing %lu tasks",(unsigned long)_tasks.count);
        for (Task *taskForId in _tasks){
            synching = YES;
            Task *task = [taskForId MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            if (task.body.length){
                [task synchWithServer:^(BOOL completed) {
                    self.synchCount--;
                    if (completed){
                        [self updateSynchCount];
                    }
                }];
            } else {
                [task MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            }
        }
    }
    
    if (_checklistItems.count){
        NSLog(@"Should be syncing %lu checklist items",(unsigned long)_checklistItems.count);
        for (ChecklistItem *itemForId in _checklistItems){
            synching = YES;
            ChecklistItem *item = [itemForId MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [item synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    NSLog(@"Successfully saved checklist item");
                    [self updateSynchCount];
                }
            }];
        }
    }
    
    if (_reports.count){
        NSLog(@"Should be syncing %lu reports",(unsigned long)_reports.count);
        for (Report *reportForId in _reports){
            synching = YES;
            Report *report = [reportForId MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [report synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    [self updateSynchCount];
                }
            }];
        }
    }
    
    if (_photos.count){
        NSLog(@"Should be syncing %lu photos",(unsigned long)_photos.count);
        for (Photo *photoForId in _photos){
            synching = YES;
            Photo *photo = [photoForId MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [photo synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    NSLog(@"Successfully saved photo");
                    [self updateSynchCount];
                }
            }];
        }
    }
    
    if (_users.count){
        NSLog(@"Should be syncing %lu users",(unsigned long)_users.count);
        for (User *userForId in self.users){
            synching = YES;
            User *user = [userForId MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [user synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    NSLog(@"Successfully saved user");
                    [self updateSynchCount];
                }
            }];
        }
    }
    
    if (_comments.count){
        NSLog(@"Should be syncing %lu comments",(unsigned long)_comments.count);
        for (Comment *c in self.comments){
            synching = YES;
            Comment *comment = [c MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [comment synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    NSLog(@"Successfully saved comment");
                    [self updateSynchCount];
                }
            }];
        }
    }
    
    if (_reminders.count){
        NSLog(@"Should be syncing %lu reminders",(unsigned long)_reminders.count);
        for (Reminder *r in self.reminders){
            synching = YES;
            Reminder *reminder = [r MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [reminder synchWithServer:^(BOOL completed) {
                self.synchCount--;
                if (completed){
                    NSLog(@"Successfully saved reminder");
                    [self updateSynchCount];
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
    [self fetchObjectsThatNeedSyncing];
    if (self.synchCount <= 0 && delegate.connected){
        synching = NO;
        [delegate removeStatusMessage];
        [delegate.synchViewController setItemsToSync:nil];
        [delegate.synchViewController setTitle:@"0 items to synchronize"];
        [delegate.synchViewController.cancelAllButton setEnabled:NO];
        [delegate.synchViewController dismiss];
    } else {
        if (self.synchCount) {
            if (delegate.connected){
                NSString *updateString = (_synchCount == 1) ? @"1 object" : [NSString stringWithFormat:@"%ld objects",(long)_synchCount];
                [delegate displayStatusMessage:[NSString stringWithFormat:@"Updating %@. Tap for progress.",updateString]];
            } else {
                NSString *updateString = (_synchCount == 1) ? @"1 object needs" : [NSString stringWithFormat:@"%ld objects need",(long)_synchCount];
                [delegate displayStatusMessage:[NSString stringWithFormat:@"%@ to be synchronized",updateString]];
            }
        } else {
            [delegate displayStatusMessage:kDeviceOfflineMessage];
        }
        if (delegate.synchViewController){
            NSMutableOrderedSet *itemsToSync = [NSMutableOrderedSet orderedSetWithArray:_tasks];
            [itemsToSync addObjectsFromArray:_projects];
            [itemsToSync addObjectsFromArray:_checklistItems];
            [itemsToSync addObjectsFromArray:_reports];
            [itemsToSync addObjectsFromArray:_reminders];
            [itemsToSync addObjectsFromArray:_comments];
            [itemsToSync addObjectsFromArray:_users];
            [delegate.synchViewController setItemsToSync:itemsToSync];
            [delegate.synchViewController setTitle:[NSString stringWithFormat:@"Synching %lu items",(unsigned long)itemsToSync.count]];
            [delegate.synchViewController.cancelAllButton setEnabled:YES];
        }
    }
    [delegate.synchViewController.tableView reloadData];
}

- (void)cancelSynch {
    if (self.syncDelegate && [self.syncDelegate respondsToSelector:@selector(cancelSync)]){
        [self.syncDelegate cancelSync];
    }
    [ProgressHUD show:@"Canceling synchronization..."];
    synching = NO;
    NSArray *reports = [Report MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *tasks = [Task MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *checklistItems = [ChecklistItem MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *photos = [Photo MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *comments = [Comment MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *reminders = [Reminder MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *projects = [Project MR_findByAttribute:@"saved" withValue:@NO inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        [report setSaved:@YES];
    }];
    [tasks enumerateObjectsUsingBlock:^(Task *task, NSUInteger idx, BOOL *stop) {
        [task setSaved:@YES];
    }];
    [checklistItems enumerateObjectsUsingBlock:^(ChecklistItem *item, NSUInteger idx, BOOL *stop) {
        [item setSaved:@YES];
    }];
    [photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        [photo setSaved:@YES];
    }];
    [comments enumerateObjectsUsingBlock:^(Comment *comment, NSUInteger idx, BOOL *stop) {
        [comment setSaved:@YES];
    }];
    [reminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
        [reminder setSaved:@YES];
    }];
    [projects enumerateObjectsUsingBlock:^(Project *project, NSUInteger idx, BOOL *stop) {
        [project setSaved:@YES];
    }];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self setSynchCount:0];
    [delegate.syncController update];
    [delegate hideSyncController];
}

@end
