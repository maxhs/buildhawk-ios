//
//  Tasklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Project, Task;

@interface Tasklist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSOrderedSet *activities;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSOrderedSet *tasks;
@end

@interface Tasklist (CoreDataGeneratedAccessors)

@end
