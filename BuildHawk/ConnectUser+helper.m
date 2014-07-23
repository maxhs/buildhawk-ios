//
//  ConnectUser+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ConnectUser+helper.h"
#import "Company+helper.h"

@implementation ConnectUser (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"connect user dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"phone"] && [dictionary objectForKey:@"phone"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone"];
    }
    if ([dictionary objectForKey:@"full_name"] && [dictionary objectForKey:@"full_name"] != [NSNull null]) {
        self.fullname = [dictionary objectForKey:@"full_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"last_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"company"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!company){
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [company populateWithDict:[dictionary objectForKey:@"company"]];
        self.company = company;
    }
}
@end
