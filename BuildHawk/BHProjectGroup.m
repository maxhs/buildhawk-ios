//
//  BHProjectGroup.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHProjectGroup.h"

@implementation BHProjectGroup

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"projects_count"]) {
        self.projectsCount = value;
    } else if ([key isEqualToString:@"projects"]) {
        self.projects = [BHUtilities projectsFromJSONArray:value];
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

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.projects = [decoder decodeObjectForKey:@"projects"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.projects forKey:@"projects"];
}


@end
