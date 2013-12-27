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
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"category_name"]) {
        self.category = value;
    } else if ([key isEqualToString:@"subcategory_name"]) {
        self.subcategory = value;
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"item_type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"status"]) {
        self.status = value;
    } else if ([key isEqualToString:@"completed_date"] && value != [NSNull null]) {
        if ([self.status isEqualToString:kCompleted]) self.completed = YES;
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [BHUtilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"comments"]) {
        self.comments = [BHUtilities commentsFromJSONArray:value];
    } else if ([key isEqualToString:@"project_id"]) {
        self.projectId = value;
    } else if ([key isEqualToString:@"critical_date"] && value != [NSNull null]) {
        //self.dueDate = [BHUtilities parseDate:value];
        //self.dueDateString = [BHUtilities parseDateReturnString:value];
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

@end
