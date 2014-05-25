//
//  Company+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Company+helper.h"
#import "Subcontractor.h"
#import "User+helper.h"

@implementation Company (helper)
- (void)populateWithDict:(NSDictionary *)dictionary {
    //NSLog(@"company dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
    if ([dictionary objectForKey:@"subcontractors"] && [dictionary objectForKey:@"subcontractors"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubcontractors = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subcontractors];
        for (id subDict in [dictionary objectForKey:@"subcontractors"]){
            //NSLog(@"sub dict: %@",subDict);
            NSPredicate *subPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
            Subcontractor *subcontractor = [Subcontractor MR_findFirstWithPredicate:subPredicate];
            if (subcontractor){
                subcontractor.usersCount = [subDict objectForKey:@"users_count"];
                //NSLog(@"found saved subcontractor: %@, %@",subcontractor.name,subcontractor.identifier);
            } else {
                subcontractor = [Subcontractor MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                subcontractor.identifier = [subDict objectForKey:@"id"];
                subcontractor.name = [subDict objectForKey:@"name"];
                subcontractor.usersCount = [subDict objectForKey:@"users_count"];
                //NSLog(@"couldn't find saved subcontractor, created a new one: %@, %@",subcontractor.name, subcontractor.identifier);
            }
            [orderedSubcontractors addObject:subcontractor];
        }
        self.subcontractors = orderedSubcontractors;
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
