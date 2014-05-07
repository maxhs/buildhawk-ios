//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Address.h"
#import "Cat.h"
#import "Checklist.h"
#import "Company.h"
#import "User.h"
#import "Report+helper.h"
#import "Sub.h"

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) id group;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id notifications;
@property (nonatomic, retain) id photos;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) id recentDocuments;
@property (nonatomic, retain) Address *address;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *checklistCategories;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *subs;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *upcomingItems;
@property (nonatomic, retain) NSOrderedSet *recentItems;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)insertObject:(Cat *)value inChecklistCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChecklistCategoriesAtIndex:(NSUInteger)idx;
- (void)insertChecklistCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChecklistCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChecklistCategoriesAtIndex:(NSUInteger)idx withObject:(Cat *)value;
- (void)replaceChecklistCategoriesAtIndexes:(NSIndexSet *)indexes withChecklistCategories:(NSArray *)values;
- (void)addChecklistCategoriesObject:(Cat *)value;
- (void)removeChecklistCategoriesObject:(Cat *)value;
- (void)addChecklistCategories:(NSOrderedSet *)values;
- (void)removeChecklistCategories:(NSOrderedSet *)values;
- (void)insertObject:(Report *)value inReportsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReportsAtIndex:(NSUInteger)idx;
- (void)insertReports:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReportsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReportsAtIndex:(NSUInteger)idx withObject:(Report *)value;
- (void)replaceReportsAtIndexes:(NSIndexSet *)indexes withReports:(NSArray *)values;
- (void)addReportsObject:(Report *)value;
- (void)removeReportsObject:(Report *)value;
- (void)addReports:(NSOrderedSet *)values;
- (void)removeReports:(NSOrderedSet *)values;
- (void)insertObject:(Sub *)value inSubsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSubsAtIndex:(NSUInteger)idx;
- (void)insertSubs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSubsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSubsAtIndex:(NSUInteger)idx withObject:(Sub *)value;
- (void)replaceSubsAtIndexes:(NSIndexSet *)indexes withSubs:(NSArray *)values;
- (void)addSubsObject:(Sub *)value;
- (void)removeSubsObject:(Sub *)value;
- (void)addSubs:(NSOrderedSet *)values;
- (void)removeSubs:(NSOrderedSet *)values;
- (void)insertObject:(User *)value inUsersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUsersAtIndex:(NSUInteger)idx;
- (void)insertUsers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUsersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUsersAtIndex:(NSUInteger)idx withObject:(User *)value;
- (void)replaceUsersAtIndexes:(NSIndexSet *)indexes withUsers:(NSArray *)values;
- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSOrderedSet *)values;
- (void)removeUsers:(NSOrderedSet *)values;
- (void)insertObject:(ChecklistItem *)value inUpcomingItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUpcomingItemsAtIndex:(NSUInteger)idx;
- (void)insertUpcomingItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUpcomingItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUpcomingItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceUpcomingItemsAtIndexes:(NSIndexSet *)indexes withUpcomingItems:(NSArray *)values;
- (void)addUpcomingItemsObject:(ChecklistItem *)value;
- (void)removeUpcomingItemsObject:(ChecklistItem *)value;
- (void)addUpcomingItems:(NSOrderedSet *)values;
- (void)removeUpcomingItems:(NSOrderedSet *)values;
- (void)insertObject:(ChecklistItem *)value inRecentItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentItemsAtIndex:(NSUInteger)idx;
- (void)insertRecentItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceRecentItemsAtIndexes:(NSIndexSet *)indexes withRecentItems:(NSArray *)values;
- (void)addRecentItemsObject:(ChecklistItem *)value;
- (void)removeRecentItemsObject:(ChecklistItem *)value;
- (void)addRecentItems:(NSOrderedSet *)values;
- (void)removeRecentItems:(NSOrderedSet *)values;
@end
