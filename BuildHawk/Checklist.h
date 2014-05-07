//
//  Checklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Checklist, ChecklistCategory, ChecklistItem;

@interface Checklist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSOrderedSet *items;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *categories;
@end

@interface Checklist (CoreDataGeneratedAccessors)

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
- (void)addCatgoriesObject:(ChecklistCategory *)value;
- (void)removeCatgoriesObject:(ChecklistCategory *)value;
- (void)addCatgories:(NSSet *)values;
- (void)removeCatgories:(NSSet *)values;

@end
