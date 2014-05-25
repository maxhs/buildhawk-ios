//
//  Phase+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Phase+helper.h"
#import "Phase.h"

@implementation Phase (helper)

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
    if ([dictionary objectForKey:@"categories"] && [dictionary objectForKey:@"categories"] != [NSNull null]) {
        //[[NSManagedObjectContext MR_contextForCurrentThread] performBlock:^{
        NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *categoryDict in [dictionary objectForKey:@"categories"]) {
            Cat *category = [Cat MR_findFirstByAttribute:@"identifier" withValue:[categoryDict objectForKey:@"id"]];
            if (!category){
                category = [Cat MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [category populateFromDictionary:categoryDict];
            [categories addObject:category];
            category.phase = self;
        }
        self.categories = categories;
        //}];
    }
}

- (void)addCategory:(Cat *)category{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.categories];
    [set addObject:category];
    self.categories = set;
}
- (void)removeCategory:(Cat *)category{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.categories];
    [set removeObject:category];
    self.categories = set;
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
