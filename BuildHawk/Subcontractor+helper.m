//
//  Subcontractor+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Subcontractor+helper.h"
#import "User+helper.h"

@implementation Subcontractor (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        //NSLog(@"subcontractor users: %@",[dictionary objectForKey:@"users"]);
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
}

- (void)addUser:(User *)user {
    NSMutableOrderedSet *userSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    [userSet addObject:user];
    self.users = userSet;
}

@end
