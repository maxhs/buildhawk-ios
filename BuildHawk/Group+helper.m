//
//  Group+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/4/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Group+helper.h"
#import "Project+helper.h"

@implementation Group (helper)

- (void) populateWithDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"projects_count"] && [dictionary objectForKey:@"projects_count"] != [NSNull null]) {
        self.projectsCount = [dictionary objectForKey:@"projects_count"];
    }
    if ([dictionary objectForKey:@"projects"] && [dictionary objectForKey:@"projects"] != [NSNull null]) {
        NSMutableOrderedSet *orderedProjects = [NSMutableOrderedSet orderedSet];
        for (id projectDict in [dictionary objectForKey:@"projects"]){
            NSLog(@"project dict: %@",projectDict);
            NSPredicate *projectPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [projectDict objectForKey:@"id"]];
            Project *project = [Project MR_findFirstWithPredicate:projectPredicate];
            if (!project){
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:projectDict];
            [orderedProjects addObject:project];
        }
        for (Project *project in self.projects){
            if (![orderedProjects containsObject:project]){
                NSLog(@"deleting a project that no longer exists: %@",project.name);
                [project MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        self.projects = orderedProjects;
    }
}
-(void)addProject:(Project *)project {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.projects];
    [set addObject:project];
    self.projects = set;
}
-(void)removeProject:(Project *)project {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.projects];
    [set removeObject:project];
    self.projects = set;
}
@end
