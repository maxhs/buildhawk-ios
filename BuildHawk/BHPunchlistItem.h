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

@interface BHPunchlistItem : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *createdOn;
@property (nonatomic, strong) BHProject *project;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *assignees;
@property BOOL completed;

@end
