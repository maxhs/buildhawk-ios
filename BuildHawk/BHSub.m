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
        self.count = value;
    } else if ([key isEqualToString:@"phone_number"]) {
        self.phoneNumber = value;
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

/*- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.fname = [decoder decodeObjectForKey:@"fname"];
        self.lname = [decoder decodeObjectForKey:@"lname"];
        self.fullname = [decoder decodeObjectForKey:@"fullname"];
        self.authToken = [decoder decodeObjectForKey:@"authToken"];
        self.phone1 = [decoder decodeObjectForKey:@"phone1"];
        self.company = [decoder decodeObjectForKey:@"company"];
        self.coworkers = [decoder decodeObjectForKey:@"coworkers"];
        self.photo = [decoder decodeObjectForKey:@"photo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.fname forKey:@"fname"];
    [coder encodeObject:self.lname forKey:@"lname"];
    [coder encodeObject:self.fullname forKey:@"fullname"];
    [coder encodeObject:self.authToken forKey:@"authToken"];
    [coder encodeObject:self.phone1 forKey:@"phone1"];
    [coder encodeObject:self.company forKey:@"company"];
    [coder encodeObject:self.coworkers forKey:@"coworkers"];
    [coder encodeObject:self.photo forKey:@"photo"];
}*/

@end
