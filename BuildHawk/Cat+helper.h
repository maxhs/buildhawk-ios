//
//  Category+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Cat.h"

@interface Cat (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)update:(NSDictionary*)dictionary;
- (void)addItem:(ChecklistItem*)item;
- (void)removeItem:(ChecklistItem*)item;
@end
