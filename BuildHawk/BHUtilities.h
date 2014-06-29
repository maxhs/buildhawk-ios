//
//  BHUtilities.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChecklistItem.h"
#import "WorklistItem.h"
#import "Report.h"
#import "Report+helper.h"
#import "Cat.h"

@interface BHUtilities : NSObject

+ (NSMutableArray *)checklistItemsFromJSONArray:(NSArray *) array;
+ (NSDate*)parseDate:(id)value;
+ (NSString*)parseDateReturnString:(id)value;
+ (NSString*)parseDateTimeReturnString:(id)value;
+ (BOOL)isIPhone5;
@end
