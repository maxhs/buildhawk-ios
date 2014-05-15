//
//  Cat.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Phase;

@interface Cat : NSManagedObject

@property (nonatomic, retain) NSNumber * expanded;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) Phase *phase;
@property (nonatomic, retain) NSOrderedSet *items;
@property (nonatomic, retain) NSMutableArray *completedItems;
@property (nonatomic, retain) NSMutableArray *activeItems;
@property (nonatomic, retain) NSMutableArray *inProgressItems;
@end

@interface Cat (CoreDataGeneratedAccessors)

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
