//
//  BHSearchModalTransition.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSearchModalTransition.h"

@implementation BHSearchModalTransition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect endFrame = CGRectMake(20, 80, screenWidth()-40, screenHeight()-160);
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect fromFrame = fromViewController.view.frame;
        fromFrame.origin.y -= screenHeight();
        
        CGRect startFrame = endFrame;
        startFrame.origin.y += screenHeight();
        
        toViewController.view.frame = startFrame;
        toViewController.edgesForExtendedLayout = UIRectEdgeAll;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [fromViewController.view setAlpha:0.5];
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            toViewController.view.frame = endFrame;
            //[fromViewController.view setFrame:fromFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        endFrame.origin.y += screenHeight();
        
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [toViewController.view setAlpha:1.0];
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
