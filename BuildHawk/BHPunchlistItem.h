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

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *createdOn;
@property (nonatomic, strong) NSString *completedOn;
@property (nonatomic, strong) BHProject *project;
@property (nonatomic, strong) BHCompleted *completed;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *completedPhotos;
@property (nonatomic, strong) NSMutableArray *assignees;

@end
