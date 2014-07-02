//
//  Phase+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Phase.h"
#import "Cat+helper.h"

@interface Phase (helper)
- (void)update:(NSDictionary*)dictionary;
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addCategory:(Cat *)category;
- (void)removeCategory:(Cat *)category;
@end
