//
//  Activity.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Project, Report, WorklistItem;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) WorklistItem *task;
@property (nonatomic, retain) Project *project;

@end
