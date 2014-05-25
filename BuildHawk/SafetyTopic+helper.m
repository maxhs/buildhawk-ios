//
//  SafetyTopic+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "SafetyTopic+helper.h"

@implementation SafetyTopic (helper)
- (void)populateWithDict:(NSDictionary *)dictionary {
    //NSLog(@"safety topic dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]) {
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"info"] && [dictionary objectForKey:@"info"] != [NSNull null]) {
        self.info = [dictionary objectForKey:@"info"];
    }
}
@end
