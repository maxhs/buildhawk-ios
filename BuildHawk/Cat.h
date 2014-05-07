//
//  Cat.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Checklist, ChecklistItem, Project, Subcat;

@interface Cat : NSManagedObject

@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSDate * milestoneDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) NSNumber * progressCount;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *subcategories;
@property (nonatomic, retain) NSOrderedSet *checklistItems;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSNumber * expanded;
@property (nonatomic, retain) NSNumber * orderIndex;
@end

@interface Cat (CoreDataGeneratedAccessors)

- (void)insertObject:(Subcat *)value inSubcategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSubcategoriesAtIndex:(NSUInteger)idx;
- (void)insertSubcategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSubcategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSubcategoriesAtIndex:(NSUInteger)idx withObject:(Subcat *)value;
- (void)replaceSubcategoriesAtIndexes:(NSIndexSet *)indexes withSubcategories:(NSArray *)values;
- (void)addSubcategoriesObject:(Subcat *)value;
- (void)removeSubcategoriesObject:(Subcat *)value;
- (void)addSubcategories:(NSOrderedSet *)values;
- (void)removeSubcategories:(NSOrderedSet *)values;
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
@end
