//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Address, Checklist, ChecklistItem, Company, ConnectUser, Folder, Group, Message, Phase, Photo, Reminder, Report, User, Worklist, WorklistItem;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id notifications;
@property (nonatomic, retain) NSString * progressPercentage;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Address *address;
@property (nonatomic, retain) Checklist *checklist;
@property (nonatomic, retain) NSOrderedSet *companies;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) Company *companyArchives;
@property (nonatomic, retain) NSOrderedSet *documents;
@property (nonatomic, retain) NSOrderedSet *folders;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) NSOrderedSet *messages;
@property (nonatomic, retain) NSOrderedSet *pastDueReminders;
@property (nonatomic, retain) NSOrderedSet *phases;
@property (nonatomic, retain) NSOrderedSet *recentDocuments;
@property (nonatomic, retain) NSOrderedSet *recentItems;
@property (nonatomic, retain) NSOrderedSet *reminders;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *upcomingItems;
@property (nonatomic, retain) User *userArchiver;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) Worklist *worklist;
@property (nonatomic, retain) NSOrderedSet *worklistItems;
@property (nonatomic, retain) NSOrderedSet *connectUsers;
@property (nonatomic, retain) NSMutableOrderedSet *userConnectItems;
@end

@interface Project (CoreDataGeneratedAccessors)

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
- (void)insertObject:(Company *)value inCompaniesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCompaniesAtIndex:(NSUInteger)idx;
- (void)insertCompanies:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCompaniesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCompaniesAtIndex:(NSUInteger)idx withObject:(Company *)value;
- (void)replaceCompaniesAtIndexes:(NSIndexSet *)indexes withCompanies:(NSArray *)values;
- (void)addCompaniesObject:(Company *)value;
- (void)removeCompaniesObject:(Company *)value;
- (void)addCompanies:(NSOrderedSet *)values;
- (void)removeCompanies:(NSOrderedSet *)values;
- (void)insertObject:(Photo *)value inDocumentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDocumentsAtIndex:(NSUInteger)idx;
- (void)insertDocuments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDocumentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDocumentsAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replaceDocumentsAtIndexes:(NSIndexSet *)indexes withDocuments:(NSArray *)values;
- (void)addDocumentsObject:(Photo *)value;
- (void)removeDocumentsObject:(Photo *)value;
- (void)addDocuments:(NSOrderedSet *)values;
- (void)removeDocuments:(NSOrderedSet *)values;
- (void)insertObject:(Folder *)value inFoldersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFoldersAtIndex:(NSUInteger)idx;
- (void)insertFolders:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFoldersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFoldersAtIndex:(NSUInteger)idx withObject:(Folder *)value;
- (void)replaceFoldersAtIndexes:(NSIndexSet *)indexes withFolders:(NSArray *)values;
- (void)addFoldersObject:(Folder *)value;
- (void)removeFoldersObject:(Folder *)value;
- (void)addFolders:(NSOrderedSet *)values;
- (void)removeFolders:(NSOrderedSet *)values;
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
- (void)insertObject:(Reminder *)value inPastDueRemindersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPastDueRemindersAtIndex:(NSUInteger)idx;
- (void)insertPastDueReminders:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePastDueRemindersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPastDueRemindersAtIndex:(NSUInteger)idx withObject:(Reminder *)value;
- (void)replacePastDueRemindersAtIndexes:(NSIndexSet *)indexes withPastDueReminders:(NSArray *)values;
- (void)addPastDueRemindersObject:(Reminder *)value;
- (void)removePastDueRemindersObject:(Reminder *)value;
- (void)addPastDueReminders:(NSOrderedSet *)values;
- (void)removePastDueReminders:(NSOrderedSet *)values;
- (void)insertObject:(Phase *)value inPhasesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhasesAtIndex:(NSUInteger)idx;
- (void)insertPhases:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhasesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhasesAtIndex:(NSUInteger)idx withObject:(Phase *)value;
- (void)replacePhasesAtIndexes:(NSIndexSet *)indexes withPhases:(NSArray *)values;
- (void)addPhasesObject:(Phase *)value;
- (void)removePhasesObject:(Phase *)value;
- (void)addPhases:(NSOrderedSet *)values;
- (void)removePhases:(NSOrderedSet *)values;
- (void)insertObject:(Photo *)value inRecentDocumentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentDocumentsAtIndex:(NSUInteger)idx;
- (void)insertRecentDocuments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentDocumentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentDocumentsAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replaceRecentDocumentsAtIndexes:(NSIndexSet *)indexes withRecentDocuments:(NSArray *)values;
- (void)addRecentDocumentsObject:(Photo *)value;
- (void)removeRecentDocumentsObject:(Photo *)value;
- (void)addRecentDocuments:(NSOrderedSet *)values;
- (void)removeRecentDocuments:(NSOrderedSet *)values;
- (void)insertObject:(ChecklistItem *)value inRecentItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentItemsAtIndex:(NSUInteger)idx;
- (void)insertRecentItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceRecentItemsAtIndexes:(NSIndexSet *)indexes withRecentItems:(NSArray *)values;
- (void)addRecentItemsObject:(ChecklistItem *)value;
- (void)removeRecentItemsObject:(ChecklistItem *)value;
- (void)addRecentItems:(NSOrderedSet *)values;
- (void)removeRecentItems:(NSOrderedSet *)values;
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
- (void)insertObject:(ChecklistItem *)value inUpcomingItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUpcomingItemsAtIndex:(NSUInteger)idx;
- (void)insertUpcomingItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUpcomingItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUpcomingItemsAtIndex:(NSUInteger)idx withObject:(ChecklistItem *)value;
- (void)replaceUpcomingItemsAtIndexes:(NSIndexSet *)indexes withUpcomingItems:(NSArray *)values;
- (void)addUpcomingItemsObject:(ChecklistItem *)value;
- (void)removeUpcomingItemsObject:(ChecklistItem *)value;
- (void)addUpcomingItems:(NSOrderedSet *)values;
- (void)removeUpcomingItems:(NSOrderedSet *)values;
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
- (void)insertObject:(ConnectUser *)value inConnectUsersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromConnectUsersAtIndex:(NSUInteger)idx;
- (void)insertConnectUsers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeConnectUsersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInConnectUsersAtIndex:(NSUInteger)idx withObject:(ConnectUser *)value;
- (void)replaceConnectUsersAtIndexes:(NSIndexSet *)indexes withConnectUsers:(NSArray *)values;
- (void)addConnectUsersObject:(ConnectUser *)value;
- (void)removeConnectUsersObject:(ConnectUser *)value;
- (void)addConnectUsers:(NSOrderedSet *)values;
- (void)removeConnectUsers:(NSOrderedSet *)values;
@end
