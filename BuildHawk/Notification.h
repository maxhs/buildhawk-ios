//
//  Notification.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Task, Report, User, Message;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * notificationType;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) Task *task;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Message *message;

@end
