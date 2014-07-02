//
//  WorklistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Notification, Photo, User, Worklist, Project;

@interface WorklistItem : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSDate * completedAt;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSOrderedSet *assignees;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Worklist *worklist;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Notification *notification;
@end

@interface WorklistItem (CoreDataGeneratedAccessors)

- (void)insertObject:(User *)value inAssigneesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssigneesAtIndex:(NSUInteger)idx;
- (void)insertAssignees:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssigneesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssigneesAtIndex:(NSUInteger)idx withObject:(User *)value;
- (void)replaceAssigneesAtIndexes:(NSIndexSet *)indexes withAssignees:(NSArray *)values;
- (void)addAssigneesObject:(User *)value;
- (void)removeAssigneesObject:(User *)value;
- (void)addAssignees:(NSOrderedSet *)values;
- (void)removeAssignees:(NSOrderedSet *)values;
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
@end