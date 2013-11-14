//
//  BHAddress.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/15/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAddress.h"

@implementation BHAddress

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"formatted_address"]) {
        self.formattedAddress = value;
    } else if ([key isEqualToString:@"locality"]) {
        self.city = value;
    } else if ([key isEqualToString:@"street_number"]) {
        self.streetNumber = value;
    } else if ([key isEqualToString:@"loc"]) {
        self.latitude = [[value objectForKey:@"lat"] floatValue];
        self.longitude = [[value objectForKey:@"lng"] floatValue];
    } else if ([key isEqualToString:@"admin_area_level_1"]) {
        self.state = value;
    } else if ([key isEqualToString:@"route"]) {
        self.route = value;
    } else if ([key isEqualToString:@"country"]) {
        self.country = value;
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

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.formattedAddress = [decoder decodeObjectForKey:@"formattedAddress"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.route = [decoder decodeObjectForKey:@"route"];
        self.country = [decoder decodeObjectForKey:@"country"];
        self.state = [decoder decodeObjectForKey:@"state"];
        self.streetNumber = [decoder decodeObjectForKey:@"streetNumber"];
        self.latitude = [decoder decodeIntegerForKey:@"latitude"];
        self.longitude = [decoder decodeIntegerForKey:@"longitude"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [coder encodeObject:self.city forKey:@"city"];
    [coder encodeObject:self.streetNumber forKey:@"streetNumber"];
    [coder encodeObject:self.state forKey:@"state"];
    [coder encodeObject:self.route forKey:@"route"];
    [coder encodeObject:self.country forKey:@"country"];
    [coder encodeInteger:self.latitude forKey:@"latitude"];
    [coder encodeInteger:self.longitude forKey:@"longitude"];
}
@end
