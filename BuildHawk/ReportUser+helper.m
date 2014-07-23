//
//  ReportUser+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ReportUser+helper.h"

@implementation ReportUser (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
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
    if ([dictionary objectForKey:@"connect_user"] && [dictionary objectForKey:@"connect_user"] != [NSNull null]) {
        NSDictionary *connectUserDict = [dictionary objectForKey:@"connect_user"];
        if ([connectUserDict objectForKey:@"id"] && [connectUserDict objectForKey:@"id"] != [NSNull null]) {
            self.connectUserId = [connectUserDict objectForKey:@"id"];
        }
        if ([connectUserDict objectForKey:@"full_name"] && [connectUserDict objectForKey:@"full_name"] != [NSNull null]) {
            self.fullname = [connectUserDict objectForKey:@"full_name"];
        }
    }
    if ([dictionary objectForKey:@"hours"] && [dictionary objectForKey:@"hours"] != [NSNull null]) {
        self.hours = [dictionary objectForKey:@"hours"];
    }
}

@end
