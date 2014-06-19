//
//  Subcontractor+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Subcontractor.h"

@interface Subcontractor (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addUser:(User*)user;
@end
