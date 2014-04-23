//
//  BHPersonnel.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/14/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"
#import "BHSub.h"

@interface BHPersonnel : NSObject
@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSNumber *count;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) BHUser *user;
@property (strong, nonatomic) BHSub *sub;
- (id) initWithDictionary:(NSDictionary*)dictionary;
@end
