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
    if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"location"]) {
        self.location = value;
    } else if ([key isEqualToString:@"created"]) {
        self.createdOn = [BHUtilities parseDateTimeReturnString:[value objectForKey:@"createdOn"]];
        if ([value objectForKey:@"photos"]) {
            self.createdPhotos = [BHUtilities photosFromJSONArray:[value objectForKey:@"photos"]];
        }
    } else if ([key isEqualToString:@"completed"]) {
        if ([value objectForKey:@"photos"]) {
            self.completedPhotos = [BHUtilities photosFromJSONArray:[value objectForKey:@"photos"]];
        }
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
