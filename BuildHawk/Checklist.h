//
//  Checklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Project.h"
#import "Phase.h"
#import "ChecklistItem.h"

@interface Checklist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *phases;
@property (nonatomic, retain) NSOrderedSet *items;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Project *project;
@property (strong, nonatomic) NSMutableArray *completedPhases;
@property (strong, nonatomic) NSMutableArray *activePhases;
@property (strong, nonatomic) NSMutableArray *inProgressPhases;
@end

@interface Checklist (CoreDataGeneratedAccessors)

- (void)insertObject:(Phase *)value inPhasesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhasesAtIndex:(NSUInteger)idx;
- (void)insertPhases:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhasesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhasesAtIndex:(NSUInteger)idx withObject:(Phase *)value;
- (void)replacePhasesAtIndexes:(NSIndexSet *)indexes withPhases:(NSArray *)values;
- (void)addPhasesObject:(Phase *)value;
- (void)removePhasesObject:(Phase *)value;
- (void)addPhases:(NSOrderedSet *)values;
- (void)removePhases:(NSOrderedSet *)values;
- (void)insertObject:(ChecklistItem *)value inItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromItemsAtIndex:(NSUInteger)idx;
- (void)insertItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray *)values;
- (void)addItemsObject:(ChecklistItem *)value;
- (void)removeItemsObject:(ChecklistItem *)value;
- (void)addItems:(NSOrderedSet *)values;
- (void)removeItems:(NSOrderedSet *)values;
@end
