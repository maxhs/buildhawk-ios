//
//  ReportSub+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ReportSub+helper.h"

@implementation ReportSub (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    NSLog(@"report sub helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"count"] && [dictionary objectForKey:@"count"]) {
        self.count = [dictionary objectForKey:@"count"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
}
@end
