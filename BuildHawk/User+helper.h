//
//  User+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User.h"

@interface User (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)updateFromDictionary:(NSDictionary*)dictionary;
- (BOOL)anyAdmin;
- (void)removeNotification:(Notification*)notification;
- (void)addNotification:(Notification*)notification;
- (void)assignTask:(Task*)item;
- (void)addReminder:(Reminder*)reminder;
- (void)removeReminder:(Reminder*)reminder;
- (void)addPastDueReminder:(Reminder*)reminder;
- (void)removePastDueReminder:(Reminder*)reminder;
- (void)hideProject:(Project*)project;
- (void)activateProject:(Project*)project;
- (void)addProject:(Project*)project;
- (void)removeProject:(Project*)project;
@end
