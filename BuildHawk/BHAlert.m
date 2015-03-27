//
//  BHAlert.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHAlert.h"
#import "Constants.h"
#import "UIImage+ImageEffects.h"
#import "BHAppDelegate.h"

@interface BHAlert () {
    CGFloat dismissTime;
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
    UITapGestureRecognizer *dismissGesture;
}
@end

@implementation BHAlert

@synthesize window, background, label;

+ (BHAlert *)shared {
    static dispatch_once_t once = 0;
    static BHAlert *alert;
    dispatch_once(&once, ^{ alert = [[BHAlert alloc] init]; });
    return alert;
}

+ (void)dismiss {
    [[self shared] hideAlert];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time persist:(BOOL)persist {
    [[self shared] make:status spin:YES hide:NO withTime:time persist:persist];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time andOffset:(CGPoint)centerOffset {
    [[self shared] make:status spin:YES hide:NO withTime:time persist:NO];
}

+ (void)showSuccess:(NSString *)status {
    //[[self shared] make:status imgage:HUD_IMAGE_SUCCESS spin:NO hide:YES];
}

+ (void)showError:(NSString *)status {
    //[[self shared] make:status imgage:HUD_IMAGE_ERROR spin:NO hide:YES];
}

- (id)init {
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate respondsToSelector:@selector(window)]){
        window = [delegate performSelector:@selector(window)];
    } else {
        window = [[UIApplication sharedApplication] keyWindow];
    }
    background = nil; label = nil;
    self.alpha = 0;
    
    if (SYSTEM_VERSION >= 8.f){
        width = screenWidth();
        height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        width = screenHeight();
        height = screenWidth();
        mainScreen = CGRectMake(0, 0, height, width);
    }
    
    dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAlert)];
    dismissGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:dismissGesture];
    
    return self;
}

- (void)make:(NSString *)status spin:(BOOL)spin hide:(BOOL)hide withTime:(CGFloat)time persist:(BOOL)persist {
    dismissTime = time;
    [self create];
    label.text = status;
    label.hidden = (status == nil) ? YES : NO;
    [self orient];
    [self showAlert:persist];
}

- (void)create {
    if (background == nil) {
        background = [[UIImageView alloc] initWithImage:[self blurredSnapshotForWindow]];
        [background setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [background setFrame:mainScreen];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [self addSubview:background];
    }
    
    if (label == nil) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        if (IDIOM == IPAD) {
            label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0];
        } else {
            label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0];
        }
        
        [label setTextColor:[UIColor whiteColor]];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.numberOfLines = 0;
        [background addSubview:label];
        [label setFrame:CGRectMake(10, background.frame.size.height/2-160, background.frame.size.width-20, 320)];
    }
}

-(UIImage *)blurredSnapshotForWindow {
    UIGraphicsBeginImageContextWithOptions(mainScreen.size, NO, [UIScreen mainScreen].scale);
    [window drawViewHierarchyInRect:mainScreen afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)rotate:(NSNotification *)notification {
    [self orient];
}

- (void)orient {
    if (SYSTEM_VERSION >= 8.f){
        
    } else {
        CGFloat rotate;
        UIInterfaceOrientation orient;
        
        if (IDIOM == IPAD){
            orient = self.window.rootViewController.interfaceOrientation;
        } else {
            orient = [[UIApplication sharedApplication] statusBarOrientation];
        }
        if (orient == UIInterfaceOrientationPortrait)                   rotate = 0.0;
        else if (orient == UIInterfaceOrientationPortraitUpsideDown)	rotate = M_PI;
        else if (orient == UIInterfaceOrientationLandscapeLeft)         rotate = - M_PI_2;
        else if (orient == UIInterfaceOrientationLandscapeRight)		rotate = + M_PI_2;
        else rotate = 0.0;
        //background.transform = CGAffineTransformMakeRotation(rotate);
        label.transform = CGAffineTransformMakeRotation(rotate);
    }
}

- (void)showAlert:(BOOL)persist {
    [self.window addSubview:self];
    if (self.alpha == 0) {
        self.alpha = 1;
        background.alpha = 0;
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut;
        [UIView animateWithDuration:0.3 delay:0 options:options animations:^{
            background.alpha = 1;
        } completion:^(BOOL finished){
            if (persist){
                NSLog(@"Dismiss gesture is disabled");
                [dismissGesture setEnabled:NO];
            } else {
                [self performSelector:@selector(hideAlert) withObject:nil afterDelay:dismissTime];
            }
        }];
    }
}

- (void)hideAlert {
    if (self.alpha == 1) {
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn;
        [UIView animateWithDuration:0.3 delay:0 options:options animations:^{
            background.alpha = 0;
        } completion:^(BOOL finished) {
            [self destroy];
            self.alpha = 0;
        }];
    }
}

- (void)destroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [label removeFromSuperview];	label = nil;
    [background removeFromSuperview];	background = nil;
}

- (void)timedHide {
    @autoreleasepool
    {
        double length = label.text.length;
        NSTimeInterval sleep = length * 0.04 + 0.5;
        
        [NSThread sleepForTimeInterval:sleep];
        [self hideAlert];
    }
}


@end
