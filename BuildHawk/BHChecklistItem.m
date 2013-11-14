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
    } else if ([key isEqualToString:@"status"]) {
        self.status = value;
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [BHUtilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"comments"]) {
        self.comments = [BHUtilities commentsFromJSONArray:value];
    } else if ([key isEqualToString:@"due"]) {
        self.dueDate = [BHUtilities parseDate:value];
        self.dueDateString = [BHUtilities parseDateReturnString:value];
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

@end
