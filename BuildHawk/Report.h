//
//  Report.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/11/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Notification, Photo, Project, ReportSub, ReportUser, SafetyTopic;

@interface Report : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * dateString;
@property (nonatomic, retain) NSString * humidity;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id possibleTopics;
@property (nonatomic, retain) NSString * precip;
@property (nonatomic, retain) NSString * temp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * weather;
@property (nonatomic, retain) NSString * weatherIcon;
@property (nonatomic, retain) NSString * wind;
@property (nonatomic, retain) Notification *notification;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) User *author;
@property (nonatomic, retain) NSOrderedSet *reportSubs;
@property (nonatomic, retain) NSOrderedSet *reportUsers;
@property (nonatomic, retain) NSOrderedSet *safetyTopics;
@property (nonatomic, retain) NSOrderedSet *activities;
@end

@interface Report (CoreDataGeneratedAccessors)

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
- (void)insertObject:(ReportSub *)value inReportSubsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReportSubsAtIndex:(NSUInteger)idx;
- (void)insertReportSubs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReportSubsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReportSubsAtIndex:(NSUInteger)idx withObject:(ReportSub *)value;
- (void)replaceReportSubsAtIndexes:(NSIndexSet *)indexes withReportSubs:(NSArray *)values;
- (void)addReportSubsObject:(ReportSub *)value;
- (void)removeReportSubsObject:(ReportSub *)value;
- (void)addReportSubs:(NSOrderedSet *)values;
- (void)removeReportSubs:(NSOrderedSet *)values;
- (void)insertObject:(ReportUser *)value inReportUsersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReportUsersAtIndex:(NSUInteger)idx;
- (void)insertReportUsers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReportUsersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReportUsersAtIndex:(NSUInteger)idx withObject:(ReportUser *)value;
- (void)replaceReportUsersAtIndexes:(NSIndexSet *)indexes withReportUsers:(NSArray *)values;
- (void)addReportUsersObject:(ReportUser *)value;
- (void)removeReportUsersObject:(ReportUser *)value;
- (void)addReportUsers:(NSOrderedSet *)values;
- (void)removeReportUsers:(NSOrderedSet *)values;
- (void)insertObject:(SafetyTopic *)value inSafetyTopicsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSafetyTopicsAtIndex:(NSUInteger)idx;
- (void)insertSafetyTopics:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSafetyTopicsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSafetyTopicsAtIndex:(NSUInteger)idx withObject:(SafetyTopic *)value;
- (void)replaceSafetyTopicsAtIndexes:(NSIndexSet *)indexes withSafetyTopics:(NSArray *)values;
- (void)addSafetyTopicsObject:(SafetyTopic *)value;
- (void)removeSafetyTopicsObject:(SafetyTopic *)value;
- (void)addSafetyTopics:(NSOrderedSet *)values;
- (void)removeSafetyTopics:(NSOrderedSet *)values;
@end
