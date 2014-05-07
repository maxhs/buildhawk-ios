//
//  ChecklistCategory+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Cat.h"
#import "Subcat+helper.h"

@interface Cat (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)addSubcategory:(Subcat *)subcategory;
- (void)removeSubcategory:(Subcat *)subcategory;
@end
