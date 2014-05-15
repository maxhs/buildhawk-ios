//
//  ChecklistItem.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ChecklistItem.h"
#import "Cat.h"
#import "Checklist.h"
#import "Comment.h"
#import "Phase.h"
#import "Project.h"


@implementation ChecklistItem

@dynamic body;
@dynamic commentsCount;
@dynamic completed;
@dynamic completedDate;
@dynamic criticalDate;
@dynamic identifier;
@dynamic orderIndex;
@dynamic photos;
@dynamic photosCount;
@dynamic status;
@dynamic type;
@dynamic phase;
@dynamic checklist;
@dynamic comments;
@dynamic project;
@dynamic category;
@dynamic upcomingItems;
@synthesize filtered;

@end
