//
//  Sub+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Sub+helper.h"

@implementation Sub (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"sub helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"phone_number"] && [dictionary objectForKey:@"phone_number"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone_number"];
    }
    if ([dictionary objectForKey:@"formatted_phone"] && [dictionary objectForKey:@"formatted_phone"] != [NSNull null]) {
        self.formattedPhone = [dictionary objectForKey:@"formatted_phone"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
}

/*
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"count"]) {
 self.count = [value stringValue];
 } else if ([key isEqualToString:@"phone_number"]) {
 self.phone = value;
 } else if ([key isEqualToString:@"formatted_phone"]) {
 self.formatted_phone = value;
 } else if ([key isEqualToString:@"email"]) {
 self.email = value;
 } else if ([key isEqualToString:@"name"]) {
 self.name = value;
 }*/

@end
