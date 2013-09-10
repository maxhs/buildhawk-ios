//
//  BHProject.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHProject : NSObject
@property (nonatomic, copy) NSString *streetAddress1;
@property (nonatomic, copy) NSString *streetAddress2;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *zip;
@property (nonatomic, copy) NSMutableArray *assignees;


@end
