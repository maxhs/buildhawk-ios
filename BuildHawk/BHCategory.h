//
//  BHCategory.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHSubcategory.h"

@interface BHCategory : NSObject

@property (strong, nonatomic) NSMutableArray *children;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *progressPercentage;
@property (strong, nonatomic) NSNumber *progressCount;
@property (strong, nonatomic) NSNumber *itemCount;
@property (strong, nonatomic) NSNumber *completedCount;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
