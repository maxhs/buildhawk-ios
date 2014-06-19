//
//  Company+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Company+helper.h"
#import "Subcontractor+helper.h"
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
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        for (User *user in self.users){
            if (![orderedUsers containsObject:user]){
                NSLog(@"deleting a company user that no longer exists: %@",user.fullname);
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        self.users = orderedUsers;
    }
    if ([dictionary objectForKey:@"subcontractors"] && [dictionary objectForKey:@"subcontractors"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubcontractors = [NSMutableOrderedSet orderedSet];
        for (id subDict in [dictionary objectForKey:@"subcontractors"]){
            NSPredicate *subPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
            Subcontractor *subcontractor = [Subcontractor MR_findFirstWithPredicate:subPredicate];
            if (!subcontractor){
                subcontractor = [Subcontractor MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [subcontractor populateFromDictionary:subDict];
            [orderedSubcontractors addObject:subcontractor];
        }
        for (Subcontractor *subcontractor in self.subcontractors){
            if (![orderedSubcontractors containsObject:subcontractor]){
                NSLog(@"Deleting a subcontractor that no longer exists: %@",subcontractor.name);
                [subcontractor MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
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
