//
//  SafetyTopic.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Report, Company;

@interface SafetyTopic : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) Company *company;

@end
