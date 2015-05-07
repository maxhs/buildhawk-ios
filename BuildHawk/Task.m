//
//  Task.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Task.h"
#import "Activity.h"
#import "Comment.h"
#import "Notification.h"
#import "Photo.h"
#import "Project.h"
#import "User.h"
#import "Tasklist.h"

@implementation Task

@dynamic body;
@dynamic assigneeName;
@dynamic completed;
@dynamic approved;
@dynamic completedAt;
@dynamic createdAt;
@dynamic identifier;
@dynamic activities;
@dynamic assignees;
@dynamic comments;
@dynamic notification;
@dynamic photos;
@dynamic project;
@dynamic user;
@dynamic tasklist;
@dynamic reminders;
@dynamic saved;
@dynamic locations;

@end
