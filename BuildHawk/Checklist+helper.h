//
//  Checklist+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Checklist.h"

@interface Checklist (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary;
- (void)updateFromDictionary:(NSDictionary *)dictionary;
- (void)removePhase:(Phase *)phase;
@end
