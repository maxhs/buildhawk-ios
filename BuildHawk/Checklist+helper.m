//
//  Checklist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Checklist+helper.h"

@implementation Checklist (helper)

- (void)removePhase:(Phase *)phase{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.phases];
    [set removeObject:phase];
    self.phases = set;
}
@end
