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
    if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"title"]) {
        self.title = value;
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"subcontractors"]) {
        self.subcontractors = [BHUtilities subcontractorsFromJSONArray:value];
    } else if ([key isEqualToString:@"createdOn"]) {
        self.createdOn = [BHUtilities parseDate:value];
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
