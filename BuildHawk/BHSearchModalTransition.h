//
//  BHSearchModalTransition.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSearchModalTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
