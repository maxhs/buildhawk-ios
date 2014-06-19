//
//  Message+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/13/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Message.h"

@interface Message (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary;
@end
