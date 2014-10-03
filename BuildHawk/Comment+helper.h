//
//  Comment+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Comment.h"

@interface Comment (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)updateFromDictionary:(NSDictionary*)dictionary;
@end
