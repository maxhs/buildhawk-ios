//
//  Tasklist+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Tasklist.h"
#import "Task+helper.h"

@interface Tasklist (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)replaceTask:(Task*)task;
- (void)addTask:(Task*)task;
- (void)removeTask:(Task*)task;
@end
