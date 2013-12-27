//
//  BHChecklistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/18/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHProject.h"
#import "BHUser.h"
#import <CoreData/CoreData.h>

@interface BHChecklistItem : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *subcategory;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSDate *dueDate;
@property (nonatomic, copy) NSString *dueDateString;
@property (nonatomic, copy) BHProject *project;
@property (nonatomic, copy) NSString *projectId;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, copy) id children;
@property BOOL completed;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
