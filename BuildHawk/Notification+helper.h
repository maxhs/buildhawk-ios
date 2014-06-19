//
//  Notification+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Notification.h"

@interface Notification (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary;
@end
