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
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"created_at"]) {
        self.createdAt = [BHUtilities parseDate:[dictionary objectForKey:@"created_at"]];
        self.createdOnString = [BHUtilities parseDateTimeReturnString:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"]!=[NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (user){
            self.user = user;
        } else {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDictionary:[dictionary objectForKey:@"user"]];
            self.user = user;
        }
    }
}

/*
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"body"]) {
 self.body = value;
 } else if ([key isEqualToString:@"user"]) {
 self.user = [[BHUser alloc] initWithDictionary:value];
 } else if ([key isEqualToString:@"created_at"]) {
 self.createdOn = [BHUtilities parseDate:value];
 }*/

@end
