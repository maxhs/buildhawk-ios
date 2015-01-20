//
//  BHUtilities.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface BHUtilities : NSObject

+ (NSDate*)parseDate:(id)value;
+ (NSDate*)parseDateTime:(id)value;
+ (NSString*)parseDateReturnString:(id)value;
+ (NSString*)parseDateTimeReturnString:(id)value;
+ (BOOL)isIPhone5;
@end
