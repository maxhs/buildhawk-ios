//
//  ChecklistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/16/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Cat.h"
#import "Checklist.h"
#import "Comment.h"
#import "Notification.h"
#import "Phase.h"
#import "Photo.h"
#import "Project.h"

typedef NS_ENUM(NSInteger, ItemState) {
    kItemNotApplicable = -1,
    kItemInProgress = 0,
    kItemCompleted = 1,
};

@interface ChecklistItem : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * commentsCount;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSNumber * saved;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSDate * criticalDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSNumber * photosCount;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Cat *category;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) Notification *notification;
@property (nonatomic, retain) Phase *phase;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) NSOrderedSet *reminders;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Project *upcomingItems;
@end
