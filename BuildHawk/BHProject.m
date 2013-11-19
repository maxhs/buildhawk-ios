//
//  BHProject.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHProject.h"
#import "BHUser.h"

@implementation BHProject

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"company"]) {
        self.company = [[BHCompany alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"active"]) {
        self.active = [value boolValue];
    } else if ([key isEqualToString:@"address"]) {
        self.address = [[BHAddress alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"users"]) {
        self.users = [self coworkersFromJSONArray:value];
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
        self.type = [decoder decodeObjectForKey:@"type"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.company = [decoder decodeObjectForKey:@"company"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.users = [decoder decodeObjectForKey:@"users"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.company forKey:@"company"];
    [coder encodeObject:self.address forKey:@"address"];
    [coder encodeObject:self.users forKey:@"users"];
}

@end
