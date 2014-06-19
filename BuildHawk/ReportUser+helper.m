//
//  ReportUser+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ReportUser+helper.h"

@implementation ReportUser (helper)
//NSLog(@"checklist item helper dictionary: %@",dictionary);
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"id"] != [NSNull null]) {
        self.userId = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"hours"] != [NSNull null]) {
        self.hours = [dictionary objectForKey:@"hours"];
    }
    if ([dictionary objectForKey:@"full_name"] != [NSNull null]) {
        self.fullname = [dictionary objectForKey:@"full_name"];
    }
}

@end
