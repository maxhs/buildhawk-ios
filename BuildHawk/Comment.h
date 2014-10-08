//
//  Comment.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User+helper.h"
#import "Activity.h"
#import "ChecklistItem.h"

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * dateString;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Comment *comment;
@property (nonatomic, retain) Activity *activity;

@end
