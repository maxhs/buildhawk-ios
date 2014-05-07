//
//  ChecklistCategory+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Cat+helper.h"
#import "Cat.h"

@implementation Cat (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"category helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"completed_count"]) {
        self.completed = [dictionary objectForKey:@"completed_count"];
    }
    if ([dictionary objectForKey:@"item_count"]) {
        self.itemCount = [dictionary objectForKey:@"item_count"];
    }
    if ([dictionary objectForKey:@"progress_percentage"]) {
        self.progressPercentage = [dictionary objectForKey:@"progress_percentage"];
    }
    if ([dictionary objectForKey:@"progress_count"]) {
        self.progressCount = [dictionary objectForKey:@"progress_count"];
    }
    if ([dictionary objectForKey:@"order_index"]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"milestone_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"milestone_date"] doubleValue];
        self.milestoneDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"subcategories"] && [dictionary objectForKey:@"subcategories"] != [NSNull null]) {
        //[[NSManagedObjectContext MR_contextForCurrentThread] performBlock:^{
        NSMutableOrderedSet *subcategories = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subcategories];
        for (NSDictionary *subcategoryDict in [dictionary objectForKey:@"subcategories"]) {
            Subcat *subcategory = [Subcat MR_findFirstByAttribute:@"identifier" withValue:[subcategoryDict objectForKey:@"id"]];
            if (!subcategory){
                subcategory = [Subcat MR_createEntity];
            }
            [subcategory populateFromDictionary:subcategoryDict];
            [subcategories addObject:subcategory];
        }
        self.subcategories = subcategories;
        //}];
    }
}

- (void)addSubcategory:(Subcat *)subcategory{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subcategories];
    [set addObject:subcategory];
    self.subcategories = set;
}
- (void)removeSubcategory:(Subcat *)subcategory{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subcategories];
    [set removeObject:subcategory];
    self.subcategories = set;
}

/*if ([key isEqualToString:@"id"]) {
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
}*/
@end
