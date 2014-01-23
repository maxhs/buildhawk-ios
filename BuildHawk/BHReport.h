//
//  BHReport.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"
#import "BHProject.h"
#import <CoreData/CoreData.h>

@interface BHReport : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *createdDate;
@property (nonatomic, strong) NSString *weather;
@property (nonatomic, strong) NSString *weatherIcon;
@property (nonatomic, strong) NSString *temp;
@property (nonatomic, strong) NSString *precip;
@property (nonatomic, strong) NSString *wind;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) BHUser *user;
@property (nonatomic, strong) BHProject *project;
@property (nonatomic, strong) NSMutableArray *personnel;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *photos;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
