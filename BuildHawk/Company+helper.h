//
//  Company+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Company.h"
#import "Project+helper.h"

@interface Company (helper)
- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) update:(NSDictionary*)dictionary;
- (void) addProject:(Project*)project;
- (void) removeProject:(Project*)project;
@end
