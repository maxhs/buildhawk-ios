//
//  Task+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Task.h"
#import "Photo+helper.h"
#import "User+helper.h"
#import "Activity+helper.h"
#import "Location+helper.h"

typedef void(^synchCompletion)(BOOL completed);

@interface Task (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addComment:(Comment *)comment;
- (void)removeComment:(Comment *)comment;
- (void)addPhoto:(Photo *)photo;
- (void)removePhoto:(Photo *)photo;
- (void)addLocation:(Location *)location;
- (void)removeLocation:(Location *)location;
- (NSString *)locationsToSentence;
- (void)addAssignee:(User *)user;
- (void)removeAssignee:(User *)user;
- (NSString *)assigneesToSentence;
- (void)addActivity:(Activity *)activity;
- (void)removeActivity:(Activity *)activity;
- (void)synchWithServer:(synchCompletion)complete;
@end
