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

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"progress_percentage"]) {
        self.progressPercentage = [dictionary objectForKey:@"progress_percentage"];
    }
    if ([dictionary objectForKey:@"order_index"]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"checklist_items"] && [dictionary objectForKey:@"checklist_items"] != [NSNull null]) {
        //[[NSManagedObjectContext MR_contextForCurrentThread] performBlock:^{
            NSMutableOrderedSet *items = [NSMutableOrderedSet orderedSet];
            for (NSDictionary *itemDict in [dictionary objectForKey:@"checklist_items"]) {
                ChecklistItem *item = [ChecklistItem MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"]];
                if (!item){
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [item populateFromDictionary:itemDict];
                item.category = self;
                [items addObject:item];
            }
            self.items = items;
        //}];
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
