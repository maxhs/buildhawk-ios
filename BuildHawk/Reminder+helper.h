//
//  Reminder+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

typedef void(^synchCompletion)(BOOL completed);

#import "Reminder.h"

@interface Reminder (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;

- (void)synchWithServer:(synchCompletion)completed;
@end
