//
//  ChecklistItem+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ChecklistItem.h"

@interface ChecklistItem (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)update:(NSDictionary*)dictionary;
- (void)addComment:(Comment *)comment;
- (void)removeComment:(Comment *)comment;
- (void)addActivity:(Activity *)activity;
- (void)removeActivity:(Activity *)activity;
- (void)addPhoto:(Photo *)photo;
- (void)removePhoto:(Photo *)photo;
- (void)addReminder:(Reminder *)reminder;
- (void)removeReminder:(Reminder *)reminder;
@end
