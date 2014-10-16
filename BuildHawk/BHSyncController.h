//
//  BHSyncController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSyncController : NSObject

@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSArray *reports;
@property (strong, nonatomic) NSArray *checklistItems;
@property (strong, nonatomic) NSArray *photos;

+ (id)sharedController;
- (void)syncAll;

@end