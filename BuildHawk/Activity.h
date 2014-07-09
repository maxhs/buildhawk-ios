//
//  Activity.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Checklist, ChecklistItem, Comment, Project, Report, User, Worklist, WorklistItem, Photo;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSString * activityType;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Comment *comment;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Worklist *worklist;
@property (nonatomic, retain) WorklistItem *task;
@property (nonatomic, retain) Photo *photo;

@end
