//
//  BHCompleted.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHCompleted.h"

@implementation BHCompleted


- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"user"]) {
        self.user = [[BHUser alloc] init];
    } else if ([key isEqualToString:@"completedOn"]) {
        self.completed = YES;
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}


@end
