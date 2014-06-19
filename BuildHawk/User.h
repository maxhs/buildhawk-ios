//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Company, Notification, Project, Subcontractor, WorklistItem;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSNumber * companyAdmin;
@property (nonatomic, retain) NSNumber * emailPermissions;
@property (nonatomic, retain) NSNumber * textPermissions;
@property (nonatomic, retain) NSNumber * pushPermissions;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * formattedPhone;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photoUrlMedium;
@property (nonatomic, retain) NSString * photoUrlSmall;
@property (nonatomic, retain) NSString * photoUrlThumb;
@property (nonatomic, retain) NSNumber * uberAdmin;
@property (nonatomic, retain) NSOrderedSet *assignedWorklistItems;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *projects;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *worklistItems;
@property (nonatomic, retain) Subcontractor *subcontractor;
@property (nonatomic, retain) NSOrderedSet *notifications;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)insertObject:(WorklistItem *)value inAssignedWorklistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssignedWorklistItemsAtIndex:(NSUInteger)idx;
- (void)insertAssignedWorklistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssignedWorklistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssignedWorklistItemsAtIndex:(NSUInteger)idx withObject:(WorklistItem *)value;
- (void)replaceAssignedWorklistItemsAtIndexes:(NSIndexSet *)indexes withAssignedWorklistItems:(NSArray *)values;
- (void)addAssignedWorklistItemsObject:(WorklistItem *)value;
- (void)removeAssignedWorklistItemsObject:(WorklistItem *)value;
- (void)addAssignedWorklistItems:(NSOrderedSet *)values;
- (void)removeAssignedWorklistItems:(NSOrderedSet *)values;
- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)insertObject:(Project *)value inProjectsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromProjectsAtIndex:(NSUInteger)idx;
- (void)insertProjects:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeProjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInProjectsAtIndex:(NSUInteger)idx withObject:(Project *)value;
- (void)replaceProjectsAtIndexes:(NSIndexSet *)indexes withProjects:(NSArray *)values;
- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSOrderedSet *)values;
- (void)removeProjects:(NSOrderedSet *)values;
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
- (void)insertObject:(Notification *)value inNotificationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromNotificationsAtIndex:(NSUInteger)idx;
- (void)insertNotifications:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeNotificationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInNotificationsAtIndex:(NSUInteger)idx withObject:(Notification *)value;
- (void)replaceNotificationsAtIndexes:(NSIndexSet *)indexes withNotifications:(NSArray *)values;
- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSOrderedSet *)values;
- (void)removeNotifications:(NSOrderedSet *)values;
@end
