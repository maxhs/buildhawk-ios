//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Comment, Company, Message, Notification, Project, Reminder, Report, Subcontractor, WorklistItem;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSNumber * companyAdmin;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) id coworkers;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * emailPermissions;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * formattedPhone;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photoUrlMedium;
@property (nonatomic, retain) NSString * photoUrlSmall;
@property (nonatomic, retain) NSString * photoUrlThumb;
@property (nonatomic, retain) NSNumber * pushPermissions;
@property (nonatomic, retain) NSNumber * textPermissions;
@property (nonatomic, retain) NSNumber * uberAdmin;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) NSOrderedSet *archivedProjects;
@property (nonatomic, retain) NSOrderedSet *assignedWorklistItems;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *messages;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *projects;
@property (nonatomic, retain) NSMutableOrderedSet *reminders;
@property (nonatomic, retain) NSMutableOrderedSet *pastDueReminders;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *alternates;
@property (nonatomic, retain) Subcontractor *subcontractor;
@property (nonatomic, retain) NSOrderedSet *worklistItems;
@end

@interface User (CoreDataGeneratedAccessors)

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
- (void)insertObject:(Project *)value inArchivedProjectsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromArchivedProjectsAtIndex:(NSUInteger)idx;
- (void)insertArchivedProjects:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeArchivedProjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInArchivedProjectsAtIndex:(NSUInteger)idx withObject:(Project *)value;
- (void)replaceArchivedProjectsAtIndexes:(NSIndexSet *)indexes withArchivedProjects:(NSArray *)values;
- (void)addArchivedProjectsObject:(Project *)value;
- (void)removeArchivedProjectsObject:(Project *)value;
- (void)addArchivedProjects:(NSOrderedSet *)values;
- (void)removeArchivedProjects:(NSOrderedSet *)values;
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

- (void)insertObject:(Message *)value inMessagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMessagesAtIndex:(NSUInteger)idx;
- (void)insertMessages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMessagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMessagesAtIndex:(NSUInteger)idx withObject:(Message *)value;
- (void)replaceMessagesAtIndexes:(NSIndexSet *)indexes withMessages:(NSArray *)values;
- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSOrderedSet *)values;
- (void)removeMessages:(NSOrderedSet *)values;
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
- (void)insertObject:(Reminder *)value inRemindersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRemindersAtIndex:(NSUInteger)idx;
- (void)insertReminders:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRemindersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRemindersAtIndex:(NSUInteger)idx withObject:(Reminder *)value;
- (void)replaceRemindersAtIndexes:(NSIndexSet *)indexes withReminders:(NSArray *)values;
- (void)addRemindersObject:(Reminder *)value;
- (void)removeRemindersObject:(Reminder *)value;
- (void)addReminders:(NSOrderedSet *)values;
- (void)removeReminders:(NSOrderedSet *)values;
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
