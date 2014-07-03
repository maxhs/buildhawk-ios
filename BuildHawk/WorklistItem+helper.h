//
//  WorklistItem+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "WorklistItem.h"
#import "Photo+helper.h"
#import "User+helper.h"
#import "Activity+helper.h"

@interface WorklistItem (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addComment:(Comment *)comment;
- (void)removeComment:(Comment *)comment;
- (void)addPhoto:(Photo *)photo;
- (void)removePhoto:(Photo *)photo;
- (void)addAssignee:(User *)user;
- (void)removeAssignee:(User *)user;

- (void)addActivity:(Activity *)activity;
- (void)removeActivity:(Activity *)activity;
@end
