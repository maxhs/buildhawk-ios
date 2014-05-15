//
//  Checklist.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Checklist.h"
#import "ChecklistItem.h"
#import "Phase.h"
#import "Project.h"


@implementation Checklist

@dynamic identifier;
@dynamic phases;
@dynamic items;
@dynamic project;
@synthesize completedPhases;
@synthesize activePhases;
@synthesize inProgressPhases;
@end
