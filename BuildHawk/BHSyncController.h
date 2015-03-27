//
//  BHSyncController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project+helper.h"

typedef enum {
    kDecrement = -1,
    kUnchanged = 0,
    kIncrement = 1
} SynchDirection;

@protocol BHSyncDelegate <NSObject>
- (void)cancelSync;
@end

@interface BHSyncController : NSObject

@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSArray *reports;
@property (strong, nonatomic) NSArray *checklistItems;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSArray *users;
@property (strong, nonatomic) NSArray *comments;
@property (strong, nonatomic) NSArray *reminders;
@property (strong, nonatomic) NSArray *projects;
@property NSInteger synchCount;
@property (weak, nonatomic) id<BHSyncDelegate>syncDelegate;

+ (id)sharedController;
- (void)syncAll;
- (void)updateStatusMessage:(SynchDirection)direction;
- (void)update;
- (void)cancelSynch;
@end