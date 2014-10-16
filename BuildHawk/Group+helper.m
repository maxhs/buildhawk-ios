//
//  Group+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/4/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Group+helper.h"
#import "Project+helper.h"
#import "BHAppDelegate.h"

@implementation Group (helper)

- (void)populateWithDictionary:(NSDictionary*)dictionary {
    //NSLog(@"Populate group helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"projects"] && [dictionary objectForKey:@"projects"] != [NSNull null]) {
        NSMutableOrderedSet *orderedProjects = [NSMutableOrderedSet orderedSet];
        BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
        
        for (id projectDict in [dictionary objectForKey:@"projects"]){
            //NSLog(@"project dict: %@",projectDict);
            NSPredicate *projectPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [projectDict objectForKey:@"id"]];
            Project *project = [Project MR_findFirstWithPredicate:projectPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (project){
                [project updateFromDictionary:projectDict];
            } else {
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [project populateFromDictionary:projectDict];
            }
            
            //only add the project if it contains the current user, otherwise it means they haven't been assigned
            if (delegate.currentUser && [project.users containsObject:delegate.currentUser] && [project.hidden isEqualToNumber:@NO]){
                [orderedProjects addObject:project];
            }
        }
        
        self.projects = orderedProjects;
    }
}

- (void)updateWithDictionary:(NSDictionary*)dictionary {
    //NSLog(@"Update group helper: %@",dictionary);
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"projects"] && [dictionary objectForKey:@"projects"] != [NSNull null]) {
        NSMutableOrderedSet *orderedProjects = [NSMutableOrderedSet orderedSet];
        BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
        
        for (id projectDict in [dictionary objectForKey:@"projects"]){
            //NSLog(@"project dict: %@",projectDict);
            NSPredicate *projectPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [projectDict objectForKey:@"id"]];
            Project *project = [Project MR_findFirstWithPredicate:projectPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (project){
                [project updateFromDictionary:projectDict];
            } else {
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                 [project populateFromDictionary:projectDict];
            }
           
            //only add the project if it contains the current user, otherwise it means they haven't been assigned
            if (delegate.currentUser && [project.users containsObject:delegate.currentUser] && [project.hidden isEqualToNumber:@NO]){
                [orderedProjects addObject:project];
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
