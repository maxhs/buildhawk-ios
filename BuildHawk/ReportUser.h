//
//  ReportUser.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/11/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Report;

@interface ReportUser : NSManagedObject

@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSNumber * connectUserId;
@property (nonatomic, retain) Report *report;

@end
