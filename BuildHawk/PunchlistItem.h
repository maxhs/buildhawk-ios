//
//  PunchlistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Photo, Sub, User;

@interface PunchlistItem : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * completedAt;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) NSOrderedSet *subAssignees;
@property (nonatomic, retain) NSOrderedSet *userAssignees;
@end

@interface PunchlistItem (CoreDataGeneratedAccessors)

- (void)insertObject:(Photo *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
- (void)insertObject:(Comment *)value inCommentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCommentsAtIndex:(NSUInteger)idx;
- (void)insertComments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCommentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCommentsAtIndex:(NSUInteger)idx withObject:(Comment *)value;
- (void)replaceCommentsAtIndexes:(NSIndexSet *)indexes withComments:(NSArray *)values;
- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSOrderedSet *)values;
- (void)removeComments:(NSOrderedSet *)values;
- (void)insertObject:(Sub *)value inSubAssigneesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSubAssigneesAtIndex:(NSUInteger)idx;
- (void)insertSubAssignees:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSubAssigneesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSubAssigneesAtIndex:(NSUInteger)idx withObject:(Sub *)value;
- (void)replaceSubAssigneesAtIndexes:(NSIndexSet *)indexes withSubAssignees:(NSArray *)values;
- (void)addSubAssigneesObject:(Sub *)value;
- (void)removeSubAssigneesObject:(Sub *)value;
- (void)addSubAssignees:(NSOrderedSet *)values;
- (void)removeSubAssignees:(NSOrderedSet *)values;
- (void)insertObject:(User *)value inUserAssigneesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUserAssigneesAtIndex:(NSUInteger)idx;
- (void)insertUserAssignees:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUserAssigneesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUserAssigneesAtIndex:(NSUInteger)idx withObject:(User *)value;
- (void)replaceUserAssigneesAtIndexes:(NSIndexSet *)indexes withUserAssignees:(NSArray *)values;
- (void)addUserAssigneesObject:(User *)value;
- (void)removeUserAssigneesObject:(User *)value;
- (void)addUserAssignees:(NSOrderedSet *)values;
- (void)removeUserAssignees:(NSOrderedSet *)values;
@end
