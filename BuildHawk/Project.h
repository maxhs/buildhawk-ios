//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company, Report, Sub, User;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *subs;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) Company *company;
@end

@interface Project (CoreDataGeneratedAccessors)

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
@end
