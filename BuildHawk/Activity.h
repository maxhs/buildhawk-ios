//
//  Activity.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/11/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Checklist, ChecklistItem, Comment, Photo, Project, Report, Task, Tasklist, User;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSString * activityType;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Comment *comment;
@property (nonatomic, retain) Report *dailyReport;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Task *task;
@property (nonatomic, retain) Tasklist *tasklist;
@property (nonatomic, retain) User *user;
@end

@interface Activity (CoreDataGeneratedAccessors)

- (void)addDailyReportObject:(Report *)value;
- (void)removeDailyReportObject:(Report *)value;
- (void)addDailyReport:(NSSet *)values;
- (void)removeDailyReport:(NSSet *)values;

- (void)addReportObject:(Report *)value;
- (void)removeReportObject:(Report *)value;
- (void)addReport:(NSSet *)values;
- (void)removeReport:(NSSet *)values;

@end
