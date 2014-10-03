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
    //NSLog(@"report sub helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]){
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        if ([companyDict objectForKey:@"name"] && [companyDict objectForKey:@"name"] != [NSNull null]) {
            self.name = [companyDict objectForKey:@"name"];
        }
        if ([companyDict objectForKey:@"id"] && [companyDict objectForKey:@"id"] != [NSNull null]) {
            self.companyId = [companyDict objectForKey:@"id"];
        }
    }
    if ([dictionary objectForKey:@"count"] && [dictionary objectForKey:@"count"] != [NSNull null]) {
        self.count = [dictionary objectForKey:@"count"];
    }
    
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]){
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        if ([companyDict objectForKey:@"name"] && [companyDict objectForKey:@"name"] != [NSNull null]) {
            self.name = [companyDict objectForKey:@"name"];
        }
    }
    if ([dictionary objectForKey:@"count"] && [dictionary objectForKey:@"count"] != [NSNull null]) {
        self.count = [dictionary objectForKey:@"count"];
    }
}

@end
