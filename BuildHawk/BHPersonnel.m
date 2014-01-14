//
//  BHPersonnel.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/14/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPersonnel.h"

@implementation BHPersonnel
- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"count"]) {
        self.count = value;
    } else if ([key isEqualToString:@"user"]) {
        self.user = [[BHUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"sub"]) {
        self.sub = [[BHSub alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"name"]) {
        self.name = [value stringValue];
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
