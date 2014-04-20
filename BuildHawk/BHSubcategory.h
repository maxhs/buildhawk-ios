//
//  BHSubcategory.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHChecklistItem.h"

@interface BHSubcategory : NSObject

@property (strong, nonatomic) NSMutableArray *children;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSString *progressPercentage;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end
