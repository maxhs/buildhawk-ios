//
//  Punchlist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, PunchlistItem;

@interface Punchlist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *punchlistItems;
@end

@interface Punchlist (CoreDataGeneratedAccessors)

- (void)insertObject:(PunchlistItem *)value inPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)insertPunchlistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePunchlistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPunchlistItemsAtIndex:(NSUInteger)idx withObject:(PunchlistItem *)value;
- (void)replacePunchlistItemsAtIndexes:(NSIndexSet *)indexes withPunchlistItems:(NSArray *)values;
- (void)addPunchlistItemsObject:(PunchlistItem *)value;
- (void)removePunchlistItemsObject:(PunchlistItem *)value;
- (void)addPunchlistItems:(NSOrderedSet *)values;
- (void)removePunchlistItems:(NSOrderedSet *)values;
@end
