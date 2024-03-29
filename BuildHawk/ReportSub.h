//
//  ReportSub.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/11/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Report;

@interface ReportSub : NSManagedObject

@property (nonatomic, retain) NSNumber * companyId;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Report *report;

@end
