//
//  BHReport.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReport.h"

@implementation BHReport

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"report_type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"title"]) {
        self.title = value;
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"weather"]) {
        self.weather = value;
    } else if ([key isEqualToString:@"temp"]) {
        self.temperature = value;
    } else if ([key isEqualToString:@"wind"]) {
        self.wind = value;
    } else if ([key isEqualToString:@"weather_icon"]) {
        self.weatherIcon = value;
    } else if ([key isEqualToString:@"users"]) {
        self.users = [BHUtilities usersFromJSONArray:value];
    } else if ([key isEqualToString:@"subs"]) {
        self.subcontractors = [BHUtilities subcontractorsFromJSONArray:value];
    } else if ([key isEqualToString:@"created_date"]) {
        self.createdDate = value;
    } else if ([key isEqualToString:@"created_at"]) {
        self.createdAt = [BHUtilities parseDate:value];
    } else if ([key isEqualToString:@"updated_at"]) {
        self.updatedAt = [BHUtilities parseDate:value];
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [BHUtilities photosFromJSONArray:value];
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [super setValuesForKeysWithDictionary:keyedValues];
}

@end
