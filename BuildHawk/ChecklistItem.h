//
//  ChecklistItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Cat.h"

@class Checklist, Comment, Project;

@interface ChecklistItem : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * commentsCount;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * photosCount;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSDate * criticalDate;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSNumber * orderIndex;
@property (nonatomic, retain) id photos;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSManagedObject *subcategory;
@property (nonatomic, retain) Project *upcomingItems;
@property (nonatomic, retain) Project *recentItems;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) Cat *category;
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
@end