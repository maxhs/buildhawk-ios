//
//  Location.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet * tasks;
@property (nonatomic, retain) Project * project;
@end

@interface Location (CoreDataGeneratedAccessors)

@end
