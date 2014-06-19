//
//  Address+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Address+helper.h"

@implementation Address (helper)
- (void)populateWithDict:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"formatted_address"] != [NSNull null]){
        self.formattedAddress = [dictionary objectForKey:@"formatted_address"];
    }
    if ([dictionary objectForKey:@"longitude"] != [NSNull null]){
        self.longitude = [dictionary objectForKey:@"longitude"];
    }
    if ([dictionary objectForKey:@"latitude"] != [NSNull null]){
        self.latitude = [dictionary objectForKey:@"latitude"];
    }
    if ([dictionary objectForKey:@"city"] != [NSNull null]){
        self.city = [dictionary objectForKey:@"city"];
    }
    if ([dictionary objectForKey:@"zip"] != [NSNull null]){
        self.zip = [dictionary objectForKey:@"zip"];
    }
    if ([dictionary objectForKey:@"street1"] != [NSNull null]){
        self.street1 = [dictionary objectForKey:@"street1"];
    }
    if ([dictionary objectForKey:@"street2"] != [NSNull null]){
        self.street2 = [dictionary objectForKey:@"street2"];
    }
}

@end
