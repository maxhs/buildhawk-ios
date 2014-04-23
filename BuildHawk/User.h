//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company, Project, Report;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) id coworkers;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * fname;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * lname;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photoUrl100;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) NSOrderedSet *projects;
@property (nonatomic, retain) NSOrderedSet *reports;
@end

@interface User (CoreDataGeneratedAccessors)

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
@end
