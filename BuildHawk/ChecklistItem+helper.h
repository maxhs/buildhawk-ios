//
//  ChecklistItem+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ChecklistItem.h"
#import "Comment.h"

@interface ChecklistItem (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addComment:(Comment *)comment;
- (void)removeComment:(Comment *)comment;
@end
