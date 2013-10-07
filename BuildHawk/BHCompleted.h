//
//  BHCompleted.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"

@interface BHCompleted : NSObject

@property (strong, nonatomic) BHUser *user;
@property (strong, nonatomic) NSString *completedOn;
@property (strong, nonatomic) NSMutableArray *photos;
@property BOOL completed;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
