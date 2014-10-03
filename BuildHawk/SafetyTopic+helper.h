//
//  SafetyTopic+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "SafetyTopic.h"

@interface SafetyTopic (helper)
- (void)populateWithDict:(NSDictionary*)dictionary;
- (void)updateWithDict:(NSDictionary*)dictionary;
@end
