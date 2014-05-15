//
//  Phase.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cat, Checklist, ChecklistItem, Project;

@interface Phase : NSManagedObject

@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSNumber * expanded;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSDate * milestoneDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSNumber * progressCount;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *checklistItems;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) NSMutableArray *completedCategories;
@property (nonatomic, retain) NSMutableArray *activeCategories;
@property (nonatomic, retain) NSMutableArray *inProgressCategories;
@end

@interface Phase (CoreDataGeneratedAccessors)

- (void)insertObject:(ChecklistItem *)value inChecklistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChecklistItemsAtIndex:(NSUInteger)idx;
- (void)insertChecklistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChecklistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChecklistItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceChecklistItemsAtIndexes:(NSIndexSet *)indexes withChecklistItems:(NSArray *)values;
- (void)addChecklistItemsObject:(ChecklistItem *)value;
- (void)removeChecklistItemsObject:(ChecklistItem *)value;
- (void)addChecklistItems:(NSOrderedSet *)values;
- (void)removeChecklistItems:(NSOrderedSet *)values;
- (void)insertObject:(Cat *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(Cat *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(Cat *)value;
- (void)removeCategoriesObject:(Cat *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;
@end
