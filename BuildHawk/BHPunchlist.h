//
//  BHPunchlist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/15/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PunchlistItem.h"

@interface BHPunchlist : NSObject
@property (strong, nonatomic) NSMutableArray *listItems;

//- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
