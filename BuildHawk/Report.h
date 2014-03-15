//
//  Report.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Report : NSManagedObject

@property (nonatomic, retain) NSString * createdDate;
@property (nonatomic, retain) id photos;
@property (nonatomic, retain) id personnel;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * weather;
@property (nonatomic, retain) NSString * weatherIcon;
@property (nonatomic, retain) NSString * temp;
@property (nonatomic, retain) NSString * precip;
@property (nonatomic, retain) NSString * humidity;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) id users;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) Project *project;

@end
