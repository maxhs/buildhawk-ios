//
//  Company+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Company+helper.h"
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
            if (user){
                //NSLog(@"found saved user: %@",user.fullname);
            } else {
                user = [User MR_createEntity];
                //NSLog(@"couldn't find saved user, created a new one: %@",user.fullname);
            }
            [user populateFromDictionary:userDict];
        }
        self.users = orderedUsers;
    }
}
@end
