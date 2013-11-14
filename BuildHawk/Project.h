//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/24/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Report, User;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *reports;
@property (nonatomic, retain) NSArray *users;
@property (nonatomic, retain) User *user;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addReportsObject:(Report *)value;
- (void)removeReportsObject:(Report *)value;
- (void)addReports:(NSSet *)values;
- (void)removeReports:(NSSet *)values;

@end
