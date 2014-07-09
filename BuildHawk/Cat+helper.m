//
//  Category+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Cat+helper.h"
#import "ChecklistItem+helper.h"

@implementation Cat (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary{
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"progress_percentage"] && [dictionary objectForKey:@"progress_percentage"] != [NSNull null]) {
        self.progressPercentage = [dictionary objectForKey:@"progress_percentage"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"milestone_date"] && [dictionary objectForKey:@"milestone_date"] != [NSNull null]) {
        self.milestoneDate = [BHUtilities parseDate:[dictionary objectForKey:@"milestone_date"]];
    }
    if ([dictionary objectForKey:@"completed_date"] && [dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        self.completedDate = [BHUtilities parseDate:[dictionary objectForKey:@"completed_date"]];
    }
    if ([dictionary objectForKey:@"checklist_items"] && [dictionary objectForKey:@"checklist_items"] != [NSNull null]) {
        NSMutableOrderedSet *items = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *itemDict in [dictionary objectForKey:@"checklist_items"]) {
            ChecklistItem *item = [ChecklistItem MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"]];
            if (item){
                [item update:itemDict];
            } else {
                item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [item populateFromDictionary:itemDict];
            }
            [items addObject:item];
        }
        self.items = items;
    }
}

- (void)update:(NSDictionary *)dictionary{
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"progress_percentage"] && [dictionary objectForKey:@"progress_percentage"] != [NSNull null]) {
        self.progressPercentage = [dictionary objectForKey:@"progress_percentage"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"checklist_items"] && [dictionary objectForKey:@"checklist_items"] != [NSNull null]) {
        NSMutableOrderedSet *items = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *itemDict in [dictionary objectForKey:@"checklist_items"]) {
            ChecklistItem *item = [ChecklistItem MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"]];
            if (item){
                [item update:itemDict];
            } else {
                item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [item populateFromDictionary:itemDict];
            }
            [items addObject:item];
        }
        self.items = items;
    }
}


- (void)removeItem:(ChecklistItem *)item{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.items];
    [set removeObject:item];
    self.items = set;
}
- (void)addItem:(ChecklistItem *)item{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.items];
    [set addObject:item];
    self.items = set;
}


@end
