//
//  BHProjectGroup.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHProject.h"

@interface BHProjectGroup : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSNumber *projectsCount;
@property (nonatomic, strong) NSMutableArray *projects;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end
