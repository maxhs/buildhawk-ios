//
//  BHCategory.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHCategory.h"

@implementation BHCategory
@synthesize children;

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"progress_percentage"]) {
        self.progressPercentage = value;
    } else if ([key isEqualToString:@"item_count"]) {
        self.itemCount = value;
    } else if ([key isEqualToString:@"completed_count"]) {
        self.completedCount = value;
    } else if ([key isEqualToString:@"progress_count"]) {
        self.progressCount = value;
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}
@end
