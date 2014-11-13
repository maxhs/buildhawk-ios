//
//  Photo+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Photo.h"

typedef void(^synchCompletion)(BOOL completed);

@interface Photo (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)updateFromDictionary:(NSDictionary*)dictionary;
- (void)synchWithServer:(synchCompletion)completed;
@end
