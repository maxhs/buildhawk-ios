//
//  BHSafetyTopicTransition.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSafetyTopicTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
