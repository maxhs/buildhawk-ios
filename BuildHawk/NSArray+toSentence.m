//
//  NSArray+toSentence.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/12/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "NSArray+toSentence.h"

@implementation NSArray (toSentence)

- (NSString *)toSentence {
    if (self.count <= 2) return [self componentsJoinedByString:@" and "];
    NSArray *allButLastObject = [self subarrayWithRange:NSMakeRange(0, self.count-1)];
    NSString *result = [allButLastObject componentsJoinedByString:@", "];
    return [result stringByAppendingFormat:@", and %@", self.lastObject];
}

@end
