//
//  User+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User+helper.h"

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
    if ([dictionary objectForKey:@"phone_number"] && [dictionary objectForKey:@"phone_number"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone_number"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"demo"] && [dictionary objectForKey:@"demo"] != [NSNull null]) {
        self.demo = [dictionary objectForKey:@"demo"];
    }
    if ([dictionary objectForKey:@"admin"] && [dictionary objectForKey:@"admin"] != [NSNull null]) {
        NSLog(@"is user admin? %@ %@",[dictionary objectForKey:@"admin"], [[dictionary objectForKey:@"admin"] class]);
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [companyDict objectForKey:@"id"]];
        Company *company = [Company MR_findFirstWithPredicate:predicate];
        if (company){
            self.company = company;
            NSLog(@"MR_found company: %@",self.company.identifier);
        } else {
            self.company = [Company MR_createEntity];
            if ([companyDict objectForKey:@"name"] != [NSNull null]){
                self.company.name = [companyDict objectForKey:@"name"];
            }
            if ([companyDict objectForKey:@"id"] != [NSNull null]){
                self.company.identifier = [companyDict objectForKey:@"id"];
            }
            NSLog(@"Couldn't find the company. Creating a new one: %@",self.company.identifier);
        }
    }
}
/*
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
 } else if ([key isEqualToString:@"subcontractors"]) {
 self.subcontractors = [BHUtilities subcontractorsFromJSONArray:value];
 } else if ([key isEqualToString:@"admin"]) {
 self.admin = [value boolValue];
 } else if ([key isEqualToString:@"copmany_admin"]) {
 self.companyAdmin = [value boolValue];
 } else if ([key isEqualToString:@"uber_admin"]) {
 self.uberAdmin = [value boolValue];
 } else if ([key isEqualToString:@"url100"]) {
 if (value != [NSNull null]) {
 self.photo = [[BHPhoto alloc] init];
 [self.photo setUrl100:value];
 }
 }*/
@end
