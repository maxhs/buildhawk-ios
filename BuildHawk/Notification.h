//
//  Notification.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, WorklistItem, Report, User;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) WorklistItem *worklistItem;
@property (nonatomic, retain) User *user;

@end
