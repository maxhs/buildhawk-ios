//
//  BHProject.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHAddress.h"
#import "BHCompany.h"

@interface BHProject : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSMutableArray *assignees;
@property (nonatomic, strong) BHAddress *address;
@property (nonatomic, strong) BHCompany *company;
@property BOOL active;

@end
