//
//  Subcontractor.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/21/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company;

@interface Subcontractor : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber *usersCount;
@property (nonatomic, retain) NSNumber *count;
@property (nonatomic, retain) Company *company;
@property (nonatomic, retain) Report *report;

@end
