//
//  BHPunchlistItem.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/4/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistItem.h"

@implementation BHPunchlistItem

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"body"]) {
        if (value != [NSNull null] && value != nil) self.body = value;
    } else if ([key isEqualToString:@"location"]) {
        if (value != [NSNull null] && value != nil) self.location = value;
    } else if ([key isEqualToString:@"created_at"]) {
        self.createdOn = [BHUtilities parseDateTimeReturnString:value];
        //if ([value objectForKey:@"photos"]) {
        //    self.createdPhotos = [BHUtilities photosFromJSONArray:[value objectForKey:@"photos"]];
        //}
    } else if ([key isEqualToString:@"completed_at"]) {
        if (value != [NSNull null] && value != nil) self.completedOn = [BHUtilities parseDateReturnString:value];
    } else if ([key isEqualToString:@"completed"]) {
        self.completed = [value boolValue];
    } else if ([key isEqualToString:@"assignee"]) {
        if (!self.assignees) self.assignees = [NSMutableArray array];
        [self.assignees addObject:[[BHUser alloc] initWithDictionary:value]];
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [BHUtilities photosFromJSONArray:value];
    }
}

- (NSMutableArray *)coworkersFromJSONArray:(NSArray *) array {
    NSMutableArray *coworkers = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        BHUser *user = [[BHUser alloc] initWithDictionary:userDictionary];
        [coworkers addObject:user];
    }
    return coworkers;
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
