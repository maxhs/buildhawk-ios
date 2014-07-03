//
//  Worklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Project, WorklistItem;

@interface Worklist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *worklistItems;
@end

@interface Worklist (CoreDataGeneratedAccessors)

- (void)insertObject:(Activity *)value inActivitiesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromActivitiesAtIndex:(NSUInteger)idx;
- (void)insertActivities:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeActivitiesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInActivitiesAtIndex:(NSUInteger)idx withObject:(Activity *)value;
- (void)replaceActivitiesAtIndexes:(NSIndexSet *)indexes withActivities:(NSArray *)values;
- (void)addActivitiesObject:(Activity *)value;
- (void)removeActivitiesObject:(Activity *)value;
- (void)addActivities:(NSOrderedSet *)values;
- (void)removeActivities:(NSOrderedSet *)values;
- (void)insertObject:(WorklistItem *)value inWorklistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromWorklistItemsAtIndex:(NSUInteger)idx;
- (void)insertWorklistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeWorklistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInWorklistItemsAtIndex:(NSUInteger)idx withObject:(WorklistItem *)value;
- (void)replaceWorklistItemsAtIndexes:(NSIndexSet *)indexes withWorklistItems:(NSArray *)values;
- (void)addWorklistItemsObject:(WorklistItem *)value;
- (void)removeWorklistItemsObject:(WorklistItem *)value;
- (void)addWorklistItems:(NSOrderedSet *)values;
- (void)removeWorklistItems:(NSOrderedSet *)values;
@end
