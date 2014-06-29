//
//  User+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User+helper.h"
#import "WorklistItem+helper.h"

@implementation User (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"user helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"authentication_token"] && [dictionary objectForKey:@"authentication_token"] != [NSNull null]) {
        self.authToken = [dictionary objectForKey:@"authentication_token"];
    }
    if ([dictionary objectForKey:@"full_name"] && [dictionary objectForKey:@"full_name"] != [NSNull null]) {
        self.fullname = [dictionary objectForKey:@"full_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"url_medium"] && [dictionary objectForKey:@"url_medium"] != [NSNull null]) {
        self.photoUrlMedium = [dictionary objectForKey:@"url_medium"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.photoUrlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.photoUrlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"phone"] && [dictionary objectForKey:@"phone"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone"];
    }
    if ([dictionary objectForKey:@"formatted_phone"] && [dictionary objectForKey:@"formatted_phone"] != [NSNull null]) {
        self.formattedPhone = [dictionary objectForKey:@"formatted_phone"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
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
    if ([dictionary objectForKey:@"push_permissions"] && [dictionary objectForKey:@"push_permissions"] != [NSNull null]) {
        self.pushPermissions = [dictionary objectForKey:@"push_permissions"];
    }
    if ([dictionary objectForKey:@"text_permissions"] && [dictionary objectForKey:@"text_permissions"] != [NSNull null]) {
        self.textPermissions = [dictionary objectForKey:@"text_permissions"];
    }
    if ([dictionary objectForKey:@"email_permissions"] && [dictionary objectForKey:@"email_permissions"] != [NSNull null]) {
        self.emailPermissions = [dictionary objectForKey:@"email_permissions"];
    }
    if ([dictionary objectForKey:@"company"]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
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
    /*if ([dictionary objectForKey:@"connect_items"] && [dictionary objectForKey:@"connect_items"] != [NSNull null]) {
        NSMutableOrderedSet *worklistItems = [NSMutableOrderedSet orderedSet];
        for (id itemDict in [dictionary objectForKey:@"connect_items"]){
            NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
            WorklistItem *item = [WorklistItem MR_findFirstWithPredicate:itemPredicate];
            if (!item){
                item = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:itemDict];
            [worklistItems addObject:item];
        }
        self.assignedWorklistItems = worklistItems;
    }*/
}

- (void)removeNotification:(Notification*)notification {
    NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSetWithOrderedSet:self.notifications];
    [notifications removeObject:notification];
    self.notifications = notifications;
}

- (void)addNotification:(Notification*)notification {
    NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSetWithOrderedSet:self.notifications];
    [notifications addObject:notification];
    self.notifications = notifications;
}
- (void)assignWorklistItem:(WorklistItem*)item {
    NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignedWorklistItems];
    [orderedItems addObject:item];
    self.assignedWorklistItems = orderedItems;
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
 } else if ([key isEqualToString:@"phone"]) {
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
