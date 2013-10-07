//
//  BHChecklistItem.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/18/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistItem.h"

@implementation BHChecklistItem

//@dynamic identifier, completed, project, name, type, location, category, subcategory, photos;
//@synthesize children;

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"category"]) {
        self.category = value;
    } else if ([key isEqualToString:@"subcategory"]) {
        self.subcategory = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"completed"]) {
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
