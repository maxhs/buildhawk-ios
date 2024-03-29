//
//  Reminder.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Task, Project, User;

@interface Reminder : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * saved;
@property (nonatomic, retain) NSDate * reminderDate;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Task *task;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Project *pastDueProject;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) User *pastDueUser;

@end
