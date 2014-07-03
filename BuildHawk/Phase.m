//
//  Phase.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Phase.h"

@implementation Phase

@dynamic completed;
@dynamic completedDate;
@dynamic identifier;
@dynamic itemCount;
@dynamic milestoneDate;
@dynamic name;
@dynamic orderIndex;
@dynamic progressCount;
@dynamic progressPercentage;
@dynamic checklist;
@dynamic checklistItems;
@dynamic project;
@dynamic categories;
@synthesize expanded;
@synthesize completedCategories;
@synthesize activeCategories;
@synthesize inProgressCategories;

@end
