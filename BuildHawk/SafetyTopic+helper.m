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
    if ([dictionary objectForKey:@"safety_topic"] && [dictionary objectForKey:@"safety_topic"] != [NSNull null]) {
        NSDictionary *topicDict = [dictionary objectForKey:@"safety_topic"];
        if ([topicDict objectForKey:@"id"] && [topicDict objectForKey:@"id"] != [NSNull null]) {
            self.topicId = [topicDict objectForKey:@"id"];
        }
        if ([topicDict objectForKey:@"title"] && [topicDict objectForKey:@"title"] != [NSNull null]) {
            self.title = [topicDict objectForKey:@"title"];
        }
        if ([topicDict objectForKey:@"info"] && [topicDict objectForKey:@"info"] != [NSNull null]) {
            self.info = [dictionary objectForKey:@"info"];
        }
    }
}
@end
