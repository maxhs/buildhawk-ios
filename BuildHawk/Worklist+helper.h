//
//  Worklist+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Worklist.h"
#import "WorklistItem+helper.h"

@interface Worklist (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)replaceWorklistItem:(WorklistItem*)item;
- (void)addWorklistItem:(WorklistItem*)item;
- (void)removeWorklistItem:(WorklistItem*)item;
@end
