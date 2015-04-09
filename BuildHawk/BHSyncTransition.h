//
//  BHSyncTransition.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/31/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSyncTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
