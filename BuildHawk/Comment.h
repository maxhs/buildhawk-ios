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

@class ChecklistItem, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * createdOnString;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) User *user;

@end
