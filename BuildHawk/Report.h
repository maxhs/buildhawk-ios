//
//  Report.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, Sub, User;

@interface Report : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * createdDate;
@property (nonatomic, retain) NSString * humidity;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id personnel;
@property (nonatomic, retain) id photos;
@property (nonatomic, retain) NSString * precip;
@property (nonatomic, retain) NSString * temp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * weather;
@property (nonatomic, retain) NSString * weatherIcon;
@property (nonatomic, retain) NSString * wind;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) id possibleTopics;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *subs;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *safetyTopics;
@end

@interface Report (CoreDataGeneratedAccessors)

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
- (void)insertObject:(NSManagedObject *)value inSafetyTopicsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSafetyTopicsAtIndex:(NSUInteger)idx;
- (void)insertSafetyTopics:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSafetyTopicsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSafetyTopicsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceSafetyTopicsAtIndexes:(NSIndexSet *)indexes withSafetyTopics:(NSArray *)values;
- (void)addSafetyTopicsObject:(NSManagedObject *)value;
- (void)removeSafetyTopicsObject:(NSManagedObject *)value;
- (void)addSafetyTopics:(NSOrderedSet *)values;
- (void)removeSafetyTopics:(NSOrderedSet *)values;
@end
