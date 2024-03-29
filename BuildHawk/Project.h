//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Address, Checklist, ChecklistItem, Company, Folder, Group, Message, Phase, Photo, Reminder, Report, User, Task;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * active; // refers to whether the project is ACTIVE for billing purposes
@property (nonatomic, retain) NSNumber * hidden; // refers to whether the projects is hidden for the current user
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSNumber * synchronized;
@property (nonatomic, retain) NSNumber * saved;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id notifications;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Address *address;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) Company *companyHidden;
@property (nonatomic, retain) User *userHider;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) NSOrderedSet *messages;
@property (nonatomic, retain) NSOrderedSet *pastDueReminders;
@property (nonatomic, retain) NSOrderedSet *phases;
@property (nonatomic, retain) NSOrderedSet *recentDocuments;
@property (nonatomic, retain) NSOrderedSet *recentItems;
@property (nonatomic, retain) NSOrderedSet *reminders;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *upcomingItems;
@property (nonatomic, retain) NSOrderedSet *documents;
@property (nonatomic, retain) NSOrderedSet *folders;
@property (nonatomic, retain) NSOrderedSet *companies;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *tasklists;
@property (nonatomic, retain) NSOrderedSet *tasks;
@property (nonatomic, retain) NSMutableOrderedSet *userConnectItems;
@end
