//
//  Punchlist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Punchlist+helper.h"
#import "PunchlistItem+helper.h"

@implementation Punchlist (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"punchlist helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"punchlist_items"] && [dictionary objectForKey:@"punchlist_items"] != [NSNull null]) {
        NSMutableOrderedSet *punchlistItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.punchlistItems];
        for (id itemDict in [dictionary objectForKey:@"punchlist_items"]){
            NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
            PunchlistItem *item = [PunchlistItem MR_findFirstWithPredicate:itemPredicate];
            if (!item){
                item = [PunchlistItem MR_createEntity];
                NSLog(@"couldn't find saved item, created a new one: %@",item.body);
            }
            [item populateFromDictionary:itemDict];
            [punchlistItems addObject:item];
        }
        self.punchlistItems = punchlistItems;
    }
}
@end
