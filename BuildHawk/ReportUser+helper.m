//
//  ReportUser+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ReportUser+helper.h"

@implementation ReportUser (helper)

- (void)populateFromDict:(NSDictionary *)dictionary {
    //NSLog(@"reportuser helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        NSDictionary *userDict = [dictionary objectForKey:@"user"];
        if ([userDict objectForKey:@"id"] && [userDict objectForKey:@"id"] != [NSNull null]) {
            self.userId = [userDict objectForKey:@"id"];
        }
        if ([userDict objectForKey:@"full_name"] && [userDict objectForKey:@"full_name"] != [NSNull null]) {
            self.fullname = [userDict objectForKey:@"full_name"];
        }
    }

    if ([dictionary objectForKey:@"hours"] && [dictionary objectForKey:@"hours"] != [NSNull null]) {
        self.hours = [dictionary objectForKey:@"hours"];
    }
}

- (void)updateFromDict:(NSDictionary *)dictionary {

    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        NSDictionary *userDict = [dictionary objectForKey:@"user"];

        if ([userDict objectForKey:@"full_name"] && [userDict objectForKey:@"full_name"] != [NSNull null]) {
            self.fullname = [userDict objectForKey:@"full_name"];
        }
    }
    
    if ([dictionary objectForKey:@"hours"] && [dictionary objectForKey:@"hours"] != [NSNull null]) {
        self.hours = [dictionary objectForKey:@"hours"];
    }
}

@end
