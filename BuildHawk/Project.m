//
//  Project.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project.h"
#import "Activity.h"
#import "Address.h"
#import "Checklist.h"
#import "ChecklistItem.h"
#import "Company.h"
#import "Folder.h"
#import "Group.h"
#import "Message.h"
#import "Phase.h"
#import "Photo.h"
#import "Reminder.h"
#import "Report.h"
#import "User.h"
#import "Tasklist.h"
#import "Task.h"

@implementation Project

@dynamic active;
@dynamic hidden;
@dynamic demo;
@dynamic identifier;
@dynamic synchronized;
@dynamic orderIndex;
@dynamic name;
@dynamic notifications;
@dynamic progressPercentage;
@dynamic activities;
@dynamic address;
@dynamic checklist;
@dynamic companies;
@dynamic company;
@dynamic companyHidden;
@dynamic documents;
@dynamic folders;
@dynamic group;
@dynamic messages;
@dynamic pastDueReminders;
@dynamic phases;
@dynamic recentDocuments;
@dynamic recentItems;
@dynamic reminders;
@dynamic reports;
@dynamic upcomingItems;
@dynamic userHider;
@dynamic users;
@dynamic tasklists;
@dynamic tasks;
@dynamic saved;

@synthesize userConnectItems;

@end
