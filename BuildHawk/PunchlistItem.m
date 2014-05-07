//
//  PunchlistItem.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "PunchlistItem.h"
#import "Comment.h"
#import "Photo.h"
#import "Sub.h"
#import "User.h"


@implementation PunchlistItem

@dynamic identifier;
@dynamic completed;
@dynamic body;
@dynamic location;
@dynamic completedAt;
@dynamic createdAt;
@dynamic photos;
@dynamic comments;
@dynamic subAssignees;
@dynamic userAssignees;

@end
