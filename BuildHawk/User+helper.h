//
//  User+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User.h"
#import "Company.h"
#import "Notification+helper.h"
#import "WorklistItem+helper.h"

@interface User (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)removeNotification:(Notification*)notification;
- (void)addNotification:(Notification*)notification;
- (void)assignWorklistItem:(WorklistItem*)item;
@end
