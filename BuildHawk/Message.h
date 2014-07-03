//
//  Message.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/13/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Notification.h"

@class Project, User;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Notification *notification;

@end
