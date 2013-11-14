//
//  User.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/24/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company, Project;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) id coworkers;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * fname;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSString * lname;
@property (nonatomic, retain) NSString * phone1;
@property (nonatomic, retain) NSString * photoUrl100;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) id bhprojects;
@property (nonatomic, retain) NSSet *projects;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet *)values;
- (void)removeProjects:(NSSet *)values;

@end
