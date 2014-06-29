//
//  ChecklistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/16/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cat, Checklist, Comment, Notification, Phase, Photo,Project;

@interface ChecklistItem : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * commentsCount;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSDate * criticalDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) NSNumber * photosCount;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Cat *category;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) Notification *notification;
@property (nonatomic, retain) Phase *phase;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) NSOrderedSet *reminders;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Project *upcomingItems;
@end

@interface ChecklistItem (CoreDataGeneratedAccessors)

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
