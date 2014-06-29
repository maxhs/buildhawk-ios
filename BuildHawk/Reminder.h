//
//  Reminder.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Project;

@interface Reminder : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * datetime;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Project *activeProject;
@property (nonatomic, retain) User *user;

@end
