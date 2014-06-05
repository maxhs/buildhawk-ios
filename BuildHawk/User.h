//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/19/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Company, Project, PunchlistItem, Report, Subcontractor;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSNumber * companyAdmin;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) id coworkers;
@property (nonatomic, retain) NSNumber * demo;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * formattedPhone;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photoUrlSmall;
@property (nonatomic, retain) NSString * photoUrlThumb;
@property (nonatomic, retain) NSNumber * uberAdmin;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) Subcontractor *subcontractor;
@property (nonatomic, retain) NSOrderedSet *projects;
@property (nonatomic, retain) NSOrderedSet *assignedPunchlistItems;
@property (nonatomic, retain) NSOrderedSet *reports;
@property (nonatomic, retain) NSOrderedSet *punchlistItems;
@end

@interface User (CoreDataGeneratedAccessors)

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
- (void)insertObject:(PunchlistItem *)value inAssignedPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssignedPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)insertAssignedPunchlistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssignedPunchlistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssignedPunchlistItemsAtIndex:(NSUInteger)idx withObject:(PunchlistItem *)value;
- (void)replaceAssignedPunchlistItemsAtIndexes:(NSIndexSet *)indexes withAssignedPunchlistItems:(NSArray *)values;
- (void)addAssignedPunchlistItemsObject:(PunchlistItem *)value;
- (void)removeAssignedPunchlistItemsObject:(PunchlistItem *)value;
- (void)addAssignedPunchlistItems:(NSOrderedSet *)values;
- (void)removeAssignedPunchlistItems:(NSOrderedSet *)values;
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
- (void)insertObject:(PunchlistItem *)value inPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPunchlistItemsAtIndex:(NSUInteger)idx;
- (void)insertPunchlistItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePunchlistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPunchlistItemsAtIndex:(NSUInteger)idx withObject:(PunchlistItem *)value;
- (void)replacePunchlistItemsAtIndexes:(NSIndexSet *)indexes withPunchlistItems:(NSArray *)values;
- (void)addPunchlistItemsObject:(PunchlistItem *)value;
- (void)removePunchlistItemsObject:(PunchlistItem *)value;
- (void)addPunchlistItems:(NSOrderedSet *)values;
- (void)removePunchlistItems:(NSOrderedSet *)values;
@end
