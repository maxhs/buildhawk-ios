//
//  Project.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sub, User;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id users;
@property (nonatomic, retain) id subs;
@property (nonatomic, retain) id reports;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Sub *sub;

@end
