//
//  Checklist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Checklist+helper.h"

@implementation Checklist (helper)

- (void)removeCategory:(Cat *)category{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.categories];
    [set removeObject:category];
    self.categories = set;
}
@end
