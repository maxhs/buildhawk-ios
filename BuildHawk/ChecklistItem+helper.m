//
//  ChecklistItem+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ChecklistItem+helper.h"

@implementation ChecklistItem (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"checklist item helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }

    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }

    if ([dictionary objectForKey:@"item_type"] && [dictionary objectForKey:@"item_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"item_type"];
    }
    if ([dictionary objectForKey:@"subcategory_name"]) {
        //self. = [dictionary objectForKey:@"subcategory_name"];
    }
    if ([dictionary objectForKey:@"status"] && [dictionary objectForKey:@"status"] != [NSNull null]) {
        self.status = [dictionary objectForKey:@"status"];
    }
    if ([dictionary objectForKey:@"photos_count"] && [dictionary objectForKey:@"photos_count"] != [NSNull null]) {
        self.photosCount = [dictionary objectForKey:@"photos_count"];
    }
    if ([dictionary objectForKey:@"critical_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"critical_date"] doubleValue];
        self.criticalDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}

-(void)addComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set addObject:comment];
    self.comments = set;
}
-(void)removeComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set removeObject:comment];
    self.comments = set;
}

/*- (void)setValue:(id)value forKey:(NSString *)key {
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
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
 } else if ([key isEqualToString:@"photos_count"]) {
 if (value != [NSNull null] && value != nil) {
 self.photosCount = value;
 }
 } else if ([key isEqualToString:@"comments_count"]) {
 if (value != [NSNull null] && value != nil) {
 self.commentsCount = value;
 }
 } else if ([key isEqualToString:@"completed_date"] && value != [NSNull null]) {
 if ([self.status isEqualToString:kCompleted]) self.completed = YES;
 } else if ([key isEqualToString:@"photos"]) {
 self.photos = [BHUtilities photosFromJSONArray:value];
 } else if ([key isEqualToString:@"comments"]) {
 self.comments = [BHUtilities commentsFromJSONArray:value];
 } else if ([key isEqualToString:@"project_id"]) {
 self.projectId = value;
 }
 }*/

@end
