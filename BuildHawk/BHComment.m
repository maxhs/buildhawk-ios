//
//  BHComment.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/13/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHComment.h"

@implementation BHComment

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"user"]) {
        self.user = [[BHUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"createdOn"]) {
        self.createdOn = [BHUtilities parseDate:value];
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}
@end
