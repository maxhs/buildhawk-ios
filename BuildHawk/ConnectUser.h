//
//  ConnectUser.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company;

@interface ConnectUser : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSDate *createdDate;
@property (nonatomic, retain) NSOrderedSet *tasks;
@property (nonatomic, retain) Company *company;

@end
