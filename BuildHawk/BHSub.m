//
//  BHSub.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHSub.h"

@implementation BHSub

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"count"]) {
        self.count = [value stringValue];
    } else if ([key isEqualToString:@"phone_number"]) {
        self.phone = value;
    } else if ([key isEqualToString:@"email"]) {
        self.email = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    }
}

- (NSArray *)coworkersFromJSONArray:(NSArray *) array {
    NSMutableArray *coworkers = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        BHUser *user = [[BHUser alloc] initWithDictionary:userDictionary];
        [coworkers addObject:user];
    }
    return [NSArray arrayWithArray:coworkers];
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
        self.count = [decoder decodeObjectForKey:@"count"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.email = [decoder decodeObjectForKey:@"email"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.count forKey:@"count"];
    [coder encodeObject:self.phone forKey:@"phone"];
}

@end
