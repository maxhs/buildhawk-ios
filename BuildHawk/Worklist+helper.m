//
//  Worklist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Worklist+helper.h"
#import "Project+helper.h"
#import "WorklistItem+helper.h"

@implementation Worklist (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"worklist helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"project"] && [dictionary objectForKey:@"project"] != [NSNull null]) {
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"project"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project populateFromDictionary:[dictionary objectForKey:@"project"]];
        self.project = project;
    }

    if ([dictionary objectForKey:@"worklist_items"] && [dictionary objectForKey:@"worklist_items"] != [NSNull null]) {
        NSMutableOrderedSet *worklistItems = [NSMutableOrderedSet orderedSet];
        for (id itemDict in [dictionary objectForKey:@"worklist_items"]){
            WorklistItem *item = [WorklistItem MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!item){
                item = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:itemDict];
            [worklistItems addObject:item];
        }
        self.worklistItems = worklistItems;
    }
}

- (void)replaceWorklistItem:(WorklistItem*)newItem{
    NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.worklistItems];
    [self.worklistItems enumerateObjectsUsingBlock:^(WorklistItem *task, NSUInteger idx, BOOL *stop) {
        if ([task.identifier isEqualToNumber:newItem.identifier]){
            [orderedItems replaceObjectAtIndex:idx withObject:newItem];
            self.worklistItems = orderedItems;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":task,@"idx":[NSNumber numberWithUnsignedInteger:idx]}];
            *stop = YES;
        }
    }];
}

- (void)addWorklistItem:(WorklistItem*)item{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.worklistItems];
    [set insertObject:item atIndex:0];
    self.worklistItems = set;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddTask" object:nil userInfo:@{@"task":item}];
}

- (void)removeWorklistItem:(WorklistItem*)item{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.worklistItems];
    [set removeObject:item];
    self.worklistItems = set;
}

@end
