//
//  Tasklist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Tasklist+helper.h"
#import "Project+helper.h"
#import "Task+helper.h"

@implementation Tasklist (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"tasklist helper dictionary: %@",dictionary);
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

    if ([dictionary objectForKey:@"tasks"] && [dictionary objectForKey:@"tasks"] != [NSNull null]) {
        NSMutableOrderedSet *tasks = [NSMutableOrderedSet orderedSet];
        for (id itemDict in [dictionary objectForKey:@"tasks"]){
            Task *item = [Task MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!item){
                item = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:itemDict];
            [tasks addObject:item];
        }
        self.tasks = tasks;
    }
}

- (void)replaceTask:(Task*)newItem{
    NSMutableOrderedSet *orderedTasks = [NSMutableOrderedSet orderedSetWithOrderedSet:self.tasks];
    [self.tasks enumerateObjectsUsingBlock:^(Task *task, NSUInteger idx, BOOL *stop) {
        if ([task.identifier isEqualToNumber:newItem.identifier]){
            [orderedTasks replaceObjectAtIndex:idx withObject:newItem];
            self.tasks = orderedTasks;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":task,@"idx":[NSNumber numberWithUnsignedInteger:idx]}];
            *stop = YES;
        }
    }];
}

- (void)addTask:(Task*)task{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.tasks];
    [set insertObject:task atIndex:0];
    self.tasks = set;
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"AddTask" object:nil userInfo:@{@"task":item}];
}

- (void)removeTask:(Task*)task{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.tasks];
    [set removeObject:task];
    self.tasks = set;
}

@end
