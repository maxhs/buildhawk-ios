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

@interface BHSyncController : NSObject

@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSArray *reports;
@property (strong, nonatomic) NSArray *checklistItems;
@property (strong, nonatomic) NSArray *photos;
@property int synchCount;

+ (id)sharedController;
- (void)syncAll;
- (void)updateStatusMessage:(SynchDirection)direction;
- (void)update;
- (void)cancelSynch;
@end