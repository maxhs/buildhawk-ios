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
- (void) populateFromDictionary:(NSDictionary*)dictionary;
- (void) updateFromDictionary:(NSDictionary*)dictionary;
- (void) addProject:(Project*)project;
- (void) removeProject:(Project*)project;
- (void)addUser:(User*)user;
@end
