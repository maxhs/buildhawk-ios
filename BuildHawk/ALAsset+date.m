//
//  ALAsset+date.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/17/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "ALAsset+date.h"

@implementation ALAsset (date)
- (NSDate *) date {
    return [self valueForProperty:ALAssetPropertyDate];
}
@end
