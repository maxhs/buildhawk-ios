//
//  Project.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project.h"
#import "Activity.h"
#import "Address.h"
#import "Checklist.h"
#import "ChecklistItem.h"
#import "Company.h"
#import "Group.h"
#import "Message.h"
#import "Phase.h"
#import "Photo.h"
#import "Reminder.h"
#import "Report.h"
#import "User.h"
#import "Worklist.h"
#import "WorklistItem.h"


@implementation Project

@dynamic active;
@dynamic demo;
@dynamic identifier;
@dynamic name;
@dynamic notifications;
@dynamic progressPercentage;
@dynamic activities;
@dynamic address;
@dynamic checklist;
@dynamic companies;
@dynamic company;
@dynamic companyArchives;
@dynamic documents;
@dynamic group;
@dynamic messages;
@dynamic phases;
@dynamic recentDocuments;
@dynamic recentItems;
@dynamic reminders;
@dynamic reports;
@dynamic upcomingItems;
@dynamic userArchiver;
@dynamic users;
@dynamic worklist;
@dynamic worklistItems;
@dynamic folders;

@end
