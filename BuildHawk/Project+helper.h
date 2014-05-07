//
//  Project+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project.h"
#import "User.h"
#import "ChecklistItem.h"
#import "Cat.h"

@interface Project (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary;
@end
