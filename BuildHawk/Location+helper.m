//
//  Location+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "Location+helper.h"
#import "Project+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Location (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"location helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"project_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            project.identifier = [dictionary objectForKey:@"project_id"];
        }
        self.project = project;
    }
}

@end
