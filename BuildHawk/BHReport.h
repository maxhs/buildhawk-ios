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

@interface BHReport : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *createdOn;
@property (nonatomic, strong) BHUser *user;
@property (nonatomic, strong) BHProject *project;
@property (nonatomic, strong) NSMutableArray *subcontractors;
@property (nonatomic, strong) NSMutableArray *photos;

@end
