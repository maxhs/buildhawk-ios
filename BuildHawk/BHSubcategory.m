//
//  BHSubcategory.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHSubcategory.h"
#import "BHChecklistItem.h"

@implementation BHSubcategory
@synthesize children;


- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"progress_percentage"]) {
        self.progressPercentage = value;
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}
@end
