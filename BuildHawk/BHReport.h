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

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *dateString;
@property (nonatomic, copy) BHUser *author;
@property (nonatomic, copy) BHProject *project;

@end
