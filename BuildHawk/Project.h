//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Address.h"
#import "User.h"
#import "Company.h"
#import "Punchlist.h"

@class Checklist, ChecklistItem, Phase, Report;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) id group;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id notifications;

@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) Address *address;
@property (nonatomic, retain) Punchlist *punchlist;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *phases;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *recentItems;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *upcomingItems;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *recentDocuments;
@property (nonatomic, retain) NSOrderedSet *documents;
@end

@interface Project (CoreDataGeneratedAccessors)

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
- (void)removeObjectFromSubsAtIndex:(NSUInteger)idx;
- (void)insertSubs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSubsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceSubsAtIndexes:(NSIndexSet *)indexes withSubs:(NSArray *)values;
- (void)addSubs:(NSOrderedSet *)values;
- (void)removeSubs:(NSOrderedSet *)values;
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
@end
