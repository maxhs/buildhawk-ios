//
//  BHProject.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHProject.h"
#import "BHUser.h"

@implementation BHProject

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"company"]) {
        self.company = [[BHCompany alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"active"]) {
        self.active = [value boolValue];
    } else if ([key isEqualToString:@"core"]) {
        self.demo = [value boolValue];
    } else if ([key isEqualToString:@"address"]) {
        self.address = [[BHAddress alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"users"]) {
        self.users = [self usersFromJSONArray:value];
    } else if ([key isEqualToString:@"subs"]) {
        self.subs = [BHUtilities subcontractorsFromJSONArray:value];
    } else if ([key isEqualToString:@"project_group"]) {
        self.group = [[BHProjectGroup alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"recent_documents"]) {
        self.recentDocuments = [BHUtilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"categories"]) {
        self.checklistCategories = [BHUtilities categoriesFromJSONArray:value];
    } else if ([key isEqualToString:@"upcoming_items"]) {
        self.upcomingItems = [BHUtilities checklistItemsFromJSONArray:value];
    } else if ([key isEqualToString:@"recently_completed"]) {
        self.recentItems = [BHUtilities checklistItemsFromJSONArray:value];
    } else if ([key isEqualToString:@"progress"]) {
        self.progressPercentage = value;
    }
}

- (NSMutableArray *)usersFromJSONArray:(NSArray *) array {
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        BHUser *user = [[BHUser alloc] initWithDictionary:userDictionary];
        [users addObject:user];
    }
    return users;
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
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.type = [decoder decodeObjectForKey:@"type"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.company = [decoder decodeObjectForKey:@"company"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.users = [decoder decodeObjectForKey:@"users"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.company forKey:@"company"];
    [coder encodeObject:self.address forKey:@"address"];
    [coder encodeObject:self.users forKey:@"users"];
}

@end
