//
//  PunchlistItem+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "PunchlistItem.h"
#import "Photo+helper.h"

@interface PunchlistItem (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addComment:(Comment *)comment;
- (void)removeComment:(Comment *)comment;
- (void)addPhoto:(Photo *)photo;
- (void)removePhoto:(Photo *)photo;
@end
