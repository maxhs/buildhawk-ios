//
//  BHPunchlistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/4/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHProject.h"
#import "BHUser.h"
#import "BHPhoto.h"
#import "BHCompleted.h"

@interface BHPunchlistItem : NSObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *createdOn;
@property (nonatomic, strong) NSString *completedOn;
@property (nonatomic, strong) BHProject *project;
@property BOOL completed;
@property (nonatomic, strong) BHUser *completedByUser;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSMutableArray *assignees;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
