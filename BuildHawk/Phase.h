//
//  Phase.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Checklist.h"
#import "Project.h"
#import "User+helper.h"

@interface Phase : NSManagedObject

@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSNumber * expanded;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSDate * milestoneDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSNumber * progressCount;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *checklistItems;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) NSMutableArray *completedCategories;
@property (nonatomic, retain) NSMutableArray *activeCategories;
@property (nonatomic, retain) NSMutableArray *inProgressCategories;
@end

