//
//  Company.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Company.h"
#import "Project.h"
#import "User.h"


@implementation Company

@dynamic name;
@dynamic identifier;
@dynamic users;
@dynamic projects;
@dynamic hiddenProjects;
@dynamic subcontractors;
@dynamic safetyTopics;
@dynamic groups;

@synthesize projectUsers;
@synthesize expanded;
@end
