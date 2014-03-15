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
    } else if ([key isEqualToString:@"city"]) {
        self.city = value;
    } else if ([key isEqualToString:@"street1"]) {
        self.street1 = value;
    } else if ([key isEqualToString:@"street2"]) {
        self.street2 = value;
    } else if ([key isEqualToString:@"latitude"]) {
        self.latitude = [value floatValue];
    } else if ([key isEqualToString:@"longitude"]) {
        self.longitude = [value floatValue];
    } else if ([key isEqualToString:@"state"]) {
        self.state = value;
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
        self.street1 = [decoder decodeObjectForKey:@"street1"];
        self.country = [decoder decodeObjectForKey:@"country"];
        self.state = [decoder decodeObjectForKey:@"state"];
        self.street2 = [decoder decodeObjectForKey:@"street2"];
        self.latitude = [decoder decodeIntegerForKey:@"latitude"];
        self.longitude = [decoder decodeIntegerForKey:@"longitude"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [coder encodeObject:self.city forKey:@"city"];
    [coder encodeObject:self.street1 forKey:@"street1"];
    [coder encodeObject:self.state forKey:@"state"];
    [coder encodeObject:self.street2 forKey:@"street2"];
    [coder encodeObject:self.country forKey:@"country"];
    [coder encodeInteger:self.latitude forKey:@"latitude"];
    [coder encodeInteger:self.longitude forKey:@"longitude"];
}
@end
