//
//  Worklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, WorklistItem;

@interface Worklist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *worklistItems;
@end

@interface Worklist (CoreDataGeneratedAccessors)

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
