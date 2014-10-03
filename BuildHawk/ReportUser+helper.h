//
//  ReportUser+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ReportUser.h"

@interface ReportUser (helper)

- (void)populateFromDict:(NSDictionary*)dictionary;
- (void)updateFromDict:(NSDictionary*)dictionary;

@end
