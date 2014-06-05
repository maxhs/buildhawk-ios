//
//  Group+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/4/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Group.h"

@interface Group (helper)
- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) addProject:(Project*)project;
- (void) removeProject:(Project*)project;
@end
