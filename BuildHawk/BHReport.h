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
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSDate *createdOn;
@property (nonatomic, strong) BHUser *user;
@property (nonatomic, strong) BHProject *project;
@property (nonatomic, strong) NSMutableSet *subcontractors;
@property (nonatomic, strong) NSMutableArray *photos;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
