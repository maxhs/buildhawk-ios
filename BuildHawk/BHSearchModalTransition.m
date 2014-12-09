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
    UIViewController *fromViewController, *toViewController;
    UIView *fromView,*toView;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f) {
        // iOS 8 logic
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        // iOS 7 and below logic
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect endFrame = CGRectMake(20, 80, screenWidth()-40, screenHeight()-160);
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        CGRect startFrame = endFrame;
        startFrame.origin.y += screenHeight();
        toViewController.view.frame = startFrame;
        toViewController.edgesForExtendedLayout = UIRectEdgeAll;
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        CGRect fromFrame = fromViewController.view.frame;
        fromFrame.origin.y -= screenHeight();
        
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
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
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
