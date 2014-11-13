//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Comment, Company, Message, Notification, Project, Reminder, Report, Subcontractor, Task;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSString * mobileToken;
@property (nonatomic, retain) NSNumber * companyAdmin;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) id coworkers;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * emailPermissions;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * formattedPhone;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photoUrlMedium;
@property (nonatomic, retain) NSString * photoUrlSmall;
@property (nonatomic, retain) NSString * photoUrlThumb;
@property (nonatomic, retain) NSNumber * pushPermissions;
@property (nonatomic, retain) NSNumber * textPermissions;
@property (nonatomic, retain) NSNumber * uberAdmin;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) NSOrderedSet *hiddenProjects;
@property (nonatomic, retain) NSOrderedSet *assignedTasks;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *messages;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *projects;
@property (nonatomic, retain) NSMutableOrderedSet *reminders;
@property (nonatomic, retain) NSMutableOrderedSet *pastDueReminders;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *alternates;
@property (nonatomic, retain) Subcontractor *subcontractor;
@property (nonatomic, retain) NSOrderedSet *tasks;
@end

@interface User (CoreDataGeneratedAccessors)

@end
