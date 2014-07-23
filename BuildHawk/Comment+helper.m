//
//  Comment+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Comment+helper.h"
#import "User+helper.h"

@implementation Comment (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"]!=[NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"]!=[NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"created_at"] && [dictionary objectForKey:@"created)at"]!=[NSNull null]) {
        self.createdAt = [BHUtilities parseDate:[dictionary objectForKey:@"created_at"]];
        self.createdOnString = [BHUtilities parseDateTimeReturnString:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"]!=[NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (user){
            self.user = user;
        } else {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDictionary:[dictionary objectForKey:@"user"]];
            self.user = user;
        }
    }
}

- (void)update:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"]!=[NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
}

@end
