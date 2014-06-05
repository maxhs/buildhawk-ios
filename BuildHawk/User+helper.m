//
//  User+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User+helper.h"
#import "PunchlistItem+helper.h"

@implementation User (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"checklist item helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
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
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.photoUrlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.photoUrlSmall = [dictionary objectForKey:@"url_small"];
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
    if ([dictionary objectForKey:@"demo"] && [dictionary objectForKey:@"demo"] != [NSNull null]) {
        self.demo = [dictionary objectForKey:@"demo"];
    }
    if ([dictionary objectForKey:@"admin"] && [dictionary objectForKey:@"admin"] != [NSNull null]) {
        self.admin = [dictionary objectForKey:@"admin"];
    }
    if ([dictionary objectForKey:@"company_admin"] && [dictionary objectForKey:@"company_admin"] != [NSNull null]) {
        self.companyAdmin = [dictionary objectForKey:@"company_admin"];
    }
    if ([dictionary objectForKey:@"uber_admin"] && [dictionary objectForKey:@"uber_admin"] != [NSNull null]) {
        self.uberAdmin = [dictionary objectForKey:@"uber_admin"];
    }
    if ([dictionary objectForKey:@"company"]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        //NSLog(@"companyDict: %@",companyDict);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [companyDict objectForKey:@"id"]];
        Company *company = [Company MR_findFirstWithPredicate:predicate];
        if (!company){
            self.company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            if ([companyDict objectForKey:@"name"] != [NSNull null]){
                self.company.name = [companyDict objectForKey:@"name"];
            }
            if ([companyDict objectForKey:@"id"] != [NSNull null]){
                self.company.identifier = [companyDict objectForKey:@"id"];
            }
            //NSLog(@"Couldn't find the company. Creating a new one: %@",self.company.identifier);
        }
    }
    if ([dictionary objectForKey:@"connect_items"] && [dictionary objectForKey:@"connect_items"] != [NSNull null]) {
        NSMutableOrderedSet *punchlistItems = [NSMutableOrderedSet orderedSet];
        for (id itemDict in [dictionary objectForKey:@"connect_items"]){
            NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
            PunchlistItem *item = [PunchlistItem MR_findFirstWithPredicate:itemPredicate];
            if (!item){
                item = [PunchlistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:itemDict];
            [punchlistItems addObject:item];
        }
        self.assignedPunchlistItems = punchlistItems;
    }
}
/*
 - (void)setValue:(id)value forKey:(NSString *)key {
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"email"]) {
 self.email = value;
 } else if ([key isEqualToString:@"first_name"]) {
 self.fname = value;
 } else if ([key isEqualToString:@"last_name"]) {
 self.lname = value;
 } else if ([key isEqualToString:@"full_name"]) {
 self.fullname = value;
 } else if ([key isEqualToString:@"authentication_token"]) {
 self.authToken = value;
 } else if ([key isEqualToString:@"phone_number"]) {
 self.phone = value;
 } else if ([key isEqualToString:@"formatted_phone"]) {
 self.formatted_phone = value;
 } else if ([key isEqualToString:@"company"]) {
 self.company = [[BHCompany alloc] initWithDictionary:value];
 } else if ([key isEqualToString:@"coworkers"]) {
 self.coworkers = [BHUtilities coworkersFromJSONArray:value];
 } else if ([key isEqualToString:@"admin"]) {
 self.admin = [value boolValue];
 } else if ([key isEqualToString:@"copmany_admin"]) {
 self.companyAdmin = [value boolValue];
 } else if ([key isEqualToString:@"uber_admin"]) {
 self.uberAdmin = [value boolValue];
 } else if ([key isEqualToString:@"urlThumb"]) {
 if (value != [NSNull null]) {
 self.photo = [[Photo alloc] init];
 [self.photo setUrl100:value];
 }
 }
 }
 }*/
@end
