//
//  BHPunchlist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/15/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BHPunchlistItem.h"

@interface BHPunchlist : NSObject

@property (strong, nonatomic) NSMutableArray *listItems;

@end
