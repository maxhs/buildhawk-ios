//
//  BHUtilities.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"
#import "BHChecklistItem.h"
#import "BHPunchlistItem.h"
#import "BHPhoto.h"
#import "BHComment.h"
#import "BHReport.h"
#import "BHSub.h"
#import "BHPersonnel.h"
#import "BHProjectGroup.h"

@interface BHUtilities : NSObject

+ (NSMutableArray *)coworkersFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)checklistItemsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)punchlistItemsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)photosFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)reportsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)usersFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)personnelFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)commentsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)subcontractorsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)projectsFromJSONArray:(NSArray *) array;
+ (NSMutableArray *)groupsFromJSONArray:(NSArray *) array;
+ (NSDate*)parseDate:(id)value;
+ (NSString*)parseDateReturnString:(id)value;
+ (NSString*)parseDateTimeReturnString:(id)value;
+ (BOOL)isIpad;
+ (BOOL)isIPhone5;
@end
